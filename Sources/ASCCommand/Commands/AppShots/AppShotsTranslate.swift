import ArgumentParser
import Domain
import Foundation
import Infrastructure

struct AppShotsTranslate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "translate",
        abstract: "Translate generated App Store screenshots into other locales using Gemini AI"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Path to plan.json (default: .asc/app-shots/app-shots-plan.json)")
    var plan: String = ".asc/app-shots/app-shots-plan.json"

    @Option(name: .long, help: "Source locale label (default: en)")
    var from: String = "en"

    @Option(name: .long, help: "Target locale(s) — repeatable: --to zh --to ja --to ko")
    var to: [String] = []

    @Option(name: .long, help: "Gemini API key (falls back to GEMINI_API_KEY env var)")
    var geminiApiKey: String?

    @Option(name: .long, help: "Gemini image generation model to use")
    var model: String = "gemini-3.1-flash-image-preview"

    @Option(name: .long, help: "Base output directory (default: .asc/app-shots/output)")
    var outputDir: String = ".asc/app-shots/output"

    @Option(name: .long, help: "Directory containing existing generated screenshots (default: .asc/app-shots/output)")
    var sourceDir: String = ".asc/app-shots/output"

    @Option(name: .long, help: "Output image width in pixels (default: 1320 — iPhone 6.9\")")
    var outputWidth: Int = 1320

    @Option(name: .long, help: "Output image height in pixels (default: 2868 — iPhone 6.9\")")
    var outputHeight: Int = 2868

    @Option(name: .long, help: "Named device type — overrides --output-width/height. E.g.: APP_IPHONE_69 (1320×2868), APP_IPHONE_67 (1290×2796), APP_IPHONE_65 (1260×2736), APP_IPAD_PRO_129 (2048×2732)")
    var deviceType: AppShotsDisplayType?

    @Option(name: .long, help: "Path to a reference image whose visual style (colors, typography, layout) Gemini should replicate. Content is not copied — only the aesthetic.")
    var styleReference: String?

    func run() async throws {
        let configStorage = FileAppShotsConfigStorage()
        let apiKey = try resolveApiKey(configStorage: configStorage)
        let repo = ClientProvider.makeScreenshotGenerationRepository(apiKey: apiKey, model: model)
        print(try await execute(repo: repo))
    }

    func resolveApiKey(configStorage: any AppShotsConfigStorage) throws -> String {
        try resolveGeminiApiKey(geminiApiKey, configStorage: configStorage)
    }

    func execute(repo: any ScreenshotGenerationRepository) async throws -> String {
        // Resolve effective dimensions — --device-type overrides explicit --output-width/height
        let effectiveWidth = deviceType.map { $0.dimensions.width } ?? outputWidth
        let effectiveHeight = deviceType.map { $0.dimensions.height } ?? outputHeight

        guard !to.isEmpty else {
            throw ValidationError("At least one --to locale is required. Example: --to zh --to ja")
        }

        // Load plan
        let planURL = URL(fileURLWithPath: plan)
        let planData = try Data(contentsOf: planURL)
        let loadedPlan = try JSONDecoder().decode(ScreenPlan.self, from: planData)

        // Discover existing generated screenshots from source dir
        let sourceDirURL = URL(fileURLWithPath: sourceDir)
        let contents = (try? FileManager.default.contentsOfDirectory(at: sourceDirURL, includingPropertiesForKeys: nil)) ?? []
        let existingScreenshots = contents
            .filter { ["png", "jpg", "jpeg"].contains($0.pathExtension.lowercased()) }
            .filter { $0.lastPathComponent.hasPrefix("screen-") }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        guard !existingScreenshots.isEmpty else {
            throw ValidationError(
                "No generated screenshots found in \(sourceDir). Run `asc app-shots generate` first."
            )
        }

        // Resolve optional style reference image
        let styleReferenceURL: URL? = try {
            guard let path = styleReference, !path.isEmpty else { return nil }
            let url = URL(fileURLWithPath: path)
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw ValidationError("Style reference file not found: \(path)")
            }
            return url
        }()

        let outputDirURL = URL(fileURLWithPath: outputDir)

        // Process each locale in parallel
        var localeResults: [(locale: String, count: Int, dir: String)] = []
        try await withThrowingTaskGroup(of: (locale: String, count: Int, dir: String).self) { group in
            for locale in to {
                group.addTask {
                    let translatedPlan = buildTranslationPlan(plan: loadedPlan, targetLocale: locale)
                    let images = try await repo.generateImages(
                        plan: translatedPlan,
                        screenshotURLs: existingScreenshots,
                        styleReferenceURL: styleReferenceURL
                    )

                    let localeDirURL = outputDirURL.appendingPathComponent(locale)
                    try FileManager.default.createDirectory(at: localeDirURL, withIntermediateDirectories: true)

                    for (index, data) in images.sorted(by: { $0.key < $1.key }) {
                        let fileURL = localeDirURL.appendingPathComponent("screen-\(index).png")
                        let resized = resizeImageData(data, toWidth: effectiveWidth, height: effectiveHeight)
                        try resized.write(to: fileURL)
                    }

                    return (locale: locale, count: images.count, dir: localeDirURL.path)
                }
            }

            for try await result in group {
                localeResults.append(result)
            }
        }

        localeResults.sort { $0.locale < $1.locale }
        return formatOutput(results: localeResults)
    }

    private func buildTranslationPlan(plan: ScreenPlan, targetLocale: String) -> ScreenPlan {
        let translatedScreens = plan.screens.map { screen in
            var textLines = ["  - Heading: \"\(screen.heading)\""]
            if !screen.subheading.isEmpty {
                textLines.append("  - Subheading: \"\(screen.subheading)\"")
            }
            let textList = textLines.joined(separator: "\n")

            // Replace imagePrompt entirely — do NOT forward the original design-spec prompt,
            // which would cause Gemini to regenerate the design rather than edit the text.
            let prompt = """
            You are given a finished App Store screenshot as the source image.
            Reproduce it EXACTLY — preserve every visual element: background, colors, gradients, \
            device mockup position and angle, layout, typography style, decorative effects, and spacing.
            ONLY translate these text overlays outside the device mockup to \(targetLocale):
            \(textList)
            Do NOT change any text inside the device mockup (app UI content, labels, data).
            Do NOT alter any other visual element.
            """
            return ScreenConfig(
                index: screen.index,
                screenshotFile: screen.screenshotFile,
                heading: screen.heading,
                subheading: screen.subheading,
                layoutMode: screen.layoutMode,
                visualDirection: screen.visualDirection,
                imagePrompt: prompt
            )
        }
        // Clear tagline and appDescription so buildAppContext in generateImages returns ""
        // and no design-spec context is prepended to the translation prompt.
        return ScreenPlan(
            appId: plan.appId,
            appName: plan.appName,
            tagline: "",
            appDescription: nil,
            tone: plan.tone,
            colors: plan.colors,
            screens: translatedScreens
        )
    }

    private func formatOutput(results: [(locale: String, count: Int, dir: String)]) -> String {
        switch globals.outputFormat {
        case .table:
            var lines = ["| Locale | Screens | Output Dir |", "|--------|---------|------------|"]
            for r in results {
                lines.append("| \(r.locale) | \(r.count) | \(r.dir) |")
            }
            return lines.joined(separator: "\n")
        case .markdown:
            var lines = ["## Translated Screenshots", ""]
            for r in results {
                lines.append("- **\(r.locale)**: \(r.count) screens → `\(r.dir)`")
            }
            return lines.joined(separator: "\n")
        default:
            // JSON
            let objects = results.map {
                "{\"locale\":\"\($0.locale)\",\"screens\":\($0.count),\"outputDir\":\"\($0.dir)\",\"affordances\":{}}"
            }
            let body = objects.joined(separator: globals.pretty ? ",\n  " : ",")
            if globals.pretty {
                return "{\n  \"data\" : [\n  \(body)\n  ]\n}"
            } else {
                return "{\"data\":[\(body)]}"
            }
        }
    }
}
