import ArgumentParser
import Domain
import Foundation
import Infrastructure

struct AppShotsTemplatesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "templates",
        abstract: "Browse and apply screenshot templates",
        subcommands: [AppShotsTemplatesList.self, AppShotsTemplatesGet.self, AppShotsTemplatesApply.self]
    )
}

// MARK: - List

struct AppShotsTemplatesList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List available screenshot templates"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Filter by size: portrait, landscape, portrait43, square")
    var size: ScreenSize?

    @Flag(name: .long, help: "Include self-contained HTML preview for each template")
    var preview: Bool = false

    func run() async throws {
        let repo = ClientProvider.makeTemplateRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any TemplateRepository) async throws -> String {
        let templates = try await repo.listTemplates(size: size)

        if preview {
            // Include previewHTML in affordances
            let items = templates.map { t -> [String: Any] in
                var affordances = t.affordances
                affordances["previewHTML"] = t.previewHTML
                return [
                    "id": t.id, "name": t.name,
                    "category": t.category.rawValue,
                    "description": t.description,
                    "supportedSizes": t.supportedSizes.map(\.rawValue),
                    "deviceCount": t.deviceCount,
                    "affordances": affordances,
                ]
            }
            let data = try JSONSerialization.data(
                withJSONObject: ["data": items],
                options: globals.pretty ? [.prettyPrinted, .sortedKeys] : []
            )
            return String(data: data, encoding: .utf8) ?? "{}"
        }

        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            templates,
            headers: ["ID", "Name", "Category", "Devices"],
            rowMapper: { [$0.id, $0.name, $0.category.rawValue, "\($0.deviceCount)"] }
        )
    }
}

// MARK: - Get

struct AppShotsTemplatesGet: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get details of a specific template"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Template ID")
    var id: String

    @Flag(name: .long, help: "Output self-contained HTML preview page")
    var preview: Bool = false

    func run() async throws {
        let repo = ClientProvider.makeTemplateRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any TemplateRepository) async throws -> String {
        guard let template = try await repo.getTemplate(id: id) else {
            throw ValidationError("Template '\(id)' not found. Run `asc app-shots templates list` to see available templates.")
        }

        if preview {
            return template.previewHTML
        }

        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [template],
            headers: ["ID", "Name", "Category", "Sizes", "Devices"],
            rowMapper: { [$0.id, $0.name, $0.category.rawValue, $0.supportedSizes.map(\.rawValue).joined(separator: ","), "\($0.deviceCount)"] }
        )
    }
}

// MARK: - Apply

/// Preview output format for apply commands.
enum PreviewFormat: String, CaseIterable, ExpressibleByArgument {
    case html
    case image
}

struct AppShotsTemplatesApply: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "apply",
        abstract: "Apply a template to a screenshot — returns the composed design with preview"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Template ID")
    var id: String

    @Option(name: .long, help: "Path to screenshot file")
    var screenshot: String

    @Option(name: .long, help: "Headline text")
    var headline: String

    @Option(name: .long, help: "Subtitle text")
    var subtitle: String?

    @Option(name: .long, help: "Tagline text (overrides template default)")
    var tagline: String?

    @Option(name: .long, help: "App name")
    var appName: String = "My App"

    @Option(name: .long, help: "Preview format: html (default) or image (renders to PNG)")
    var preview: PreviewFormat?

    @Option(name: .long, help: "Output PNG path (for --preview image)")
    var imageOutput: String?

    func run() async throws {
        let repo = ClientProvider.makeTemplateRepository()
        if preview == .image {
            let renderer = ClientProvider.makeHTMLRenderer()
            print(try await execute(repo: repo, renderer: renderer))
        } else {
            print(try await execute(repo: repo))
        }
    }

    func execute(repo: any TemplateRepository, renderer: (any HTMLRenderer)? = nil) async throws -> String {
        guard let template = try await repo.getTemplate(id: id) else {
            throw ValidationError("Template '\(id)' not found. Run `asc app-shots templates list` to see available templates.")
        }

        let isPreview = preview != nil

        if isPreview {
            if preview == .image, let renderer {
                // For image export, use full path so WebKit resolves it relative to cwd
                let content = TemplateContent(
                    headline: headline,
                    subtitle: subtitle,
                    tagline: tagline,
                    screenshotFile: screenshot
                )
                let html = TemplateHTMLRenderer.renderPage(template, content: content, fillViewport: true)
                return try await renderToImage(html: html, renderer: renderer)
            }

            // For HTML preview, use just filename so it works opened from same directory
            let content = TemplateContent(
                headline: headline,
                subtitle: subtitle,
                tagline: tagline,
                screenshotFile: URL(fileURLWithPath: screenshot).lastPathComponent
            )
            return TemplateHTMLRenderer.renderPage(template, content: content)
        }

        let displayFile = screenshot

        let screen = ScreenDesign(
            index: 0,
            template: template,
            screenshotFile: displayFile,
            heading: headline,
            subheading: subtitle ?? ""
        )

        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [screen],
            headers: ["Heading", "Screenshot", "Template", "Complete"],
            rowMapper: { [$0.heading, $0.screenshotFile, $0.template?.name ?? "-", $0.isComplete ? "✓" : "✗"] }
        )
    }

    private func renderToImage(html: String, renderer: any HTMLRenderer) async throws -> String {
        let width = 1320
        let height = 2868
        let pngData = try await renderer.render(html: html, width: width, height: height)
        let outputPath = imageOutput ?? ".asc/app-shots/output/screen-0.png"
        let fileURL = URL(fileURLWithPath: outputPath)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try pngData.write(to: fileURL)
        let result: [String: Any] = ["exported": outputPath, "width": width, "height": height, "bytes": pngData.count]
        let data = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}

// MARK: - ScreenSize ArgumentParser conformance

extension ScreenSize: ExpressibleByArgument {}

