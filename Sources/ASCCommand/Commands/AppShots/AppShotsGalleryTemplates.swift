import ArgumentParser
import Domain
import Foundation

struct AppShotsGalleryTemplatesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "gallery-templates",
        abstract: "Browse gallery templates (multi-screen sets)",
        subcommands: [AppShotsGalleryTemplatesList.self, AppShotsGalleryTemplatesGet.self]
    )
}

// MARK: - List

struct AppShotsGalleryTemplatesList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List available gallery templates"
    )

    @OptionGroup var globals: GlobalOptions

    func run() async throws {
        let repo = ClientProvider.makeGalleryTemplateRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any GalleryTemplateRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let galleries = try await repo.listGalleries()
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            galleries,
            headers: ["App Name", "Shots", "Template", "Ready"],
            rowMapper: { [$0.appName, "\($0.shotCount)", $0.template?.name ?? "-", $0.isReady ? "✓" : "✗"] },
            affordanceMode: affordanceMode
        )
    }
}

// MARK: - Get

struct AppShotsGalleryTemplatesGet: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get details of a specific gallery template"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Gallery template ID")
    var id: String

    @Flag(name: .long, help: "Output self-contained HTML gallery preview page")
    var preview: Bool = false

    func run() async throws {
        let repo = ClientProvider.makeGalleryTemplateRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any GalleryTemplateRepository) async throws -> String {
        guard let gallery = try await repo.getGallery(templateId: id) else {
            throw ValidationError("Gallery template '\(id)' not found. Run `asc app-shots gallery-templates list` to see available templates.")
        }

        if preview {
            return gallery.previewHTML
        }

        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [gallery],
            headers: ["App Name", "Shots", "Template", "Ready"],
            rowMapper: { [$0.appName, "\($0.shotCount)", $0.template?.name ?? "-", $0.isReady ? "✓" : "✗"] }
        )
    }
}
