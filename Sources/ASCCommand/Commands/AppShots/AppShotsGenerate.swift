import ArgumentParser
import Domain
import Foundation
import Infrastructure

struct AppShotsGenerate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate",
        abstract: "Generate App Store screenshot images using Gemini AI"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Path to plan.json (default: .asc/app-shots/app-shots-plan.json)")
    var plan: String = ".asc/app-shots/app-shots-plan.json"

    @Option(name: .long, help: "Gemini API key (falls back to GEMINI_API_KEY env var)")
    var geminiApiKey: String?

    @Option(name: .long, help: "Gemini image generation model to use")
    var model: String = "gemini-3.1-flash-image-preview"

    @Option(name: .long, help: "Directory to write generated PNG images (default: .asc/app-shots/output)")
    var outputDir: String = ".asc/app-shots/output"

    @Option(name: .long, help: "Output image width in pixels (default: 1320 — iPhone 6.9\")")
    var outputWidth: Int = 1320

    @Option(name: .long, help: "Output image height in pixels (default: 2868 — iPhone 6.9\")")
    var outputHeight: Int = 2868

    @Option(name: .long, help: "Named device type — overrides --output-width/height. E.g.: APP_IPHONE_69 (1320×2868), APP_IPHONE_67 (1290×2796), APP_IPHONE_65 (1260×2736), APP_IPAD_PRO_129 (2048×2732)")
    var deviceType: AppShotsDisplayType?

    @Option(name: .long, help: "Path to a reference image whose visual style (colors, typography, layout) Gemini should replicate. Content is not copied — only the aesthetic.")
    var styleReference: String?

    @Argument(help: "Screenshot files — omit to auto-discover *.png/*.jpg from the plan's directory")
    var screenshots: [String] = []

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

        // Load plan
        let planURL = URL(fileURLWithPath: plan)
        let planData = try Data(contentsOf: planURL)
        let loadedPlan = try JSONDecoder().decode(ScreenPlan.self, from: planData)

        // Resolve screenshots — auto-discover from plan directory if none given
        let resolvedScreenshots: [String]
        if screenshots.isEmpty {
            let planDir = planURL.deletingLastPathComponent()
            let contents = (try? FileManager.default.contentsOfDirectory(at: planDir, includingPropertiesForKeys: nil)) ?? []
            resolvedScreenshots = contents
                .filter { ["png", "jpg", "jpeg"].contains($0.pathExtension.lowercased()) }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }
                .map { $0.path }
        } else {
            resolvedScreenshots = screenshots
        }

        // Build screenshot URLs, validate they exist
        var screenshotURLs: [URL] = []
        for path in resolvedScreenshots {
            let fileURL = URL(fileURLWithPath: path)
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                throw ValidationError("Screenshot file not found: \(path)")
            }
            screenshotURLs.append(fileURL)
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

        // Create output directory
        let outputDirURL = URL(fileURLWithPath: outputDir)
        try FileManager.default.createDirectory(at: outputDirURL, withIntermediateDirectories: true)

        // Generate images (parallel Gemini calls)
        let images = try await repo.generateImages(plan: loadedPlan, screenshotURLs: screenshotURLs, styleReferenceURL: styleReferenceURL)

        // Write each image as screen-{index}.png, resized to target App Store dimensions
        var entries: [(index: Int, path: String)] = []
        for (index, data) in images.sorted(by: { $0.key < $1.key }) {
            let fileName = "screen-\(index).png"
            let fileURL = outputDirURL.appendingPathComponent(fileName)
            let resized = resizeImageData(data, toWidth: effectiveWidth, height: effectiveHeight)
            try resized.write(to: fileURL)
            entries.append((index: index, path: fileURL.path))
        }

        return formatOutput(entries: entries)
    }

    private func formatOutput(entries: [(index: Int, path: String)]) -> String {
        switch globals.outputFormat {
        case .table:
            var lines = ["| Screen | File |", "|--------|------|"]
            for entry in entries {
                lines.append("| \(entry.index)      | \(entry.path) |")
            }
            return lines.joined(separator: "\n")
        case .markdown:
            var lines = ["## Generated Screenshots", ""]
            for entry in entries {
                lines.append("- Screen \(entry.index): `\(entry.path)`")
            }
            return lines.joined(separator: "\n")
        default:
            // JSON
            let objects = entries.map { "{\"screenIndex\":\($0.index),\"file\":\"\($0.path)\"}" }
            let body = objects.joined(separator: globals.pretty ? ",\n  " : ",")
            if globals.pretty {
                return "{\n  \"generated\" : [\n  \(body)\n  ]\n}"
            } else {
                return "{\"generated\":[\(body)]}"
            }
        }
    }
}
