import ArgumentParser
import Domain
import Foundation

struct AppShotsThemesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "themes",
        abstract: "Browse visual themes for screenshot composition",
        subcommands: [AppShotsThemesList.self, AppShotsThemesGet.self, AppShotsThemesApply.self]
    )
}

// MARK: - List

struct AppShotsThemesList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List available visual themes"
    )

    @OptionGroup var globals: GlobalOptions

    func run() async throws {
        let repo = ClientProvider.makeThemeRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any ThemeRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let themes = try await repo.listThemes()
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            themes,
            headers: ["ID", "Name", "Icon", "Description"],
            rowMapper: { [$0.id, $0.name, $0.icon, $0.description] },
            affordanceMode: affordanceMode
        )
    }
}

// MARK: - Get

struct AppShotsThemesGet: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get details of a specific theme"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Theme ID")
    var id: String

    @Flag(name: .long, help: "Output the buildContext() prompt string instead of JSON")
    var context: Bool = false

    func run() async throws {
        let repo = ClientProvider.makeThemeRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any ThemeRepository) async throws -> String {
        guard let theme = try await repo.getTheme(id: id) else {
            throw ValidationError("Theme '\(id)' not found. Run `asc app-shots themes list` to see available themes.")
        }

        if context {
            return theme.buildContext()
        }

        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [theme],
            headers: ["ID", "Name", "Icon", "Description"],
            rowMapper: { [$0.id, $0.name, $0.icon, $0.description] }
        )
    }
}

// MARK: - Apply

struct AppShotsThemesApply: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "apply",
        abstract: "Apply a theme to a template — renders deterministic layout, then AI restyles"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Theme ID")
    var theme: String

    @Option(name: .long, help: "Template ID")
    var template: String

    @Option(name: .long, help: "Path to screenshot file")
    var screenshot: String

    @Option(name: .long, help: "Headline text")
    var headline: String = "Your Headline"

    @Option(name: .long, help: "Subtitle text")
    var subtitle: String?

    @Option(name: .long, help: "Tagline text (overrides template default)")
    var tagline: String?

    @Option(name: .long, help: "Canvas width in pixels (default: 1320)")
    var canvasWidth: Int = 1320

    @Option(name: .long, help: "Canvas height in pixels (default: 2868)")
    var canvasHeight: Int = 2868

    @Option(name: .long, help: "Preview format: html (default) or image (renders to PNG)")
    var preview: PreviewFormat?

    @Option(name: .long, help: "Output PNG path (for --preview image)")
    var imageOutput: String?

    @Flag(name: .long, help: "Output ThemeDesign JSON (generate once, apply to many screenshots)")
    var designOnly: Bool = false

    @Option(name: .long, help: "Apply a cached ThemeDesign JSON file instead of calling AI")
    var applyDesign: String?

    func run() async throws {
        let themeRepo = ClientProvider.makeThemeRepository()
        let templateRepo = ClientProvider.makeTemplateRepository()
        if preview == .image {
            let renderer = ClientProvider.makeHTMLRenderer()
            print(try await execute(themeRepo: themeRepo, templateRepo: templateRepo, renderer: renderer))
        } else {
            print(try await execute(themeRepo: themeRepo, templateRepo: templateRepo))
        }
    }

    func execute(themeRepo: any ThemeRepository, templateRepo: any TemplateRepository, renderer: (any HTMLRenderer)? = nil) async throws -> String {
        // Design-only mode: generate ThemeDesign JSON from AI
        if designOnly {
            let design = try await themeRepo.design(themeId: theme)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(design)
            return String(data: data, encoding: .utf8) ?? "{}"
        }

        guard let tmpl = try await templateRepo.getTemplate(id: template) else {
            throw ValidationError("Template '\(template)' not found. Run `asc app-shots templates list` to see available templates.")
        }

        let screenshotFile = (preview == .image) ? screenshot : URL(fileURLWithPath: screenshot).lastPathComponent
        let shot = AppShot(screenshot: screenshotFile, type: .feature)
        shot.headline = headline
        shot.body = subtitle
        shot.tagline = tagline

        // Apply cached design (re-render through pipeline) or compose via AI
        let themedHTML: String
        if let designPath = applyDesign {
            let designData = try Data(contentsOf: URL(fileURLWithPath: designPath))
            let design = try JSONDecoder().decode(ThemeDesign.self, from: designData)
            themedHTML = ThemeDesignApplier.apply(design, shot: shot, screenLayout: tmpl.screenLayout)
        } else {
            let fragment = tmpl.renderFragment(shot: shot)
            themedHTML = try await themeRepo.compose(themeId: theme, html: fragment, canvasWidth: canvasWidth, canvasHeight: canvasHeight)
        }

        let page = ThemedPage(body: themedHTML, width: canvasWidth, height: canvasHeight, fillViewport: preview == .image)

        if preview == .image, let renderer {
            return try await renderToImage(html: page.html, renderer: renderer)
        }

        return page.html
    }

    private func renderToImage(html: String, renderer: any HTMLRenderer) async throws -> String {
        let pngData = try await renderer.render(html: html, width: canvasWidth, height: canvasHeight)
        let outputPath = imageOutput ?? ".asc/app-shots/output/screen-0.png"
        let fileURL = URL(fileURLWithPath: outputPath)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try pngData.write(to: fileURL)
        let result: [String: Any] = ["exported": outputPath, "width": canvasWidth, "height": canvasHeight, "bytes": pngData.count]
        let data = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    // wrapInPage logic moved to Domain/ScreenshotPlans/ThemedPage.swift
}
