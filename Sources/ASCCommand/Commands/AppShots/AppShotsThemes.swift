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

    func execute(repo: any ThemeRepository) async throws -> String {
        let themes = try await repo.listThemes()
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            themes,
            headers: ["ID", "Name", "Icon", "Description"],
            rowMapper: { [$0.id, $0.name, $0.icon, $0.description] }
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

    @Option(name: .long, help: "Canvas width in pixels (default: 1320)")
    var canvasWidth: Int = 1320

    @Option(name: .long, help: "Canvas height in pixels (default: 2868)")
    var canvasHeight: Int = 2868

    func run() async throws {
        let themeRepo = ClientProvider.makeThemeRepository()
        let templateRepo = ClientProvider.makeTemplateRepository()
        print(try await execute(themeRepo: themeRepo, templateRepo: templateRepo))
    }

    func execute(themeRepo: any ThemeRepository, templateRepo: any TemplateRepository) async throws -> String {
        // Resolve template
        guard let tmpl = try await templateRepo.getTemplate(id: template) else {
            throw ValidationError("Template '\(template)' not found. Run `asc app-shots templates list` to see available templates.")
        }

        // Step 1: Render deterministic HTML from template
        let content = TemplateContent(headline: headline, subtitle: subtitle, screenshotFile: screenshot)
        let baseHTML = TemplateHTMLRenderer.render(tmpl, content: content)

        // Step 2: Compose with theme via provider's AI backend
        let themedHTML = try await themeRepo.compose(
            themeId: theme,
            html: baseHTML,
            canvasWidth: canvasWidth,
            canvasHeight: canvasHeight
        )

        return themedHTML
    }
}
