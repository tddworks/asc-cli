import ArgumentParser
import Domain
import Infrastructure

struct AppShotsTemplatesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "templates",
        abstract: "Browse and apply screenshot templates",
        subcommands: [AppShotsTemplatesList.self, AppShotsTemplatesGet.self]
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

    func run() async throws {
        let repo = ClientProvider.makeTemplateRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any TemplateRepository) async throws -> String {
        let templates = try await repo.listTemplates(size: size)
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

    func run() async throws {
        let repo = ClientProvider.makeTemplateRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any TemplateRepository) async throws -> String {
        guard let template = try await repo.getTemplate(id: id) else {
            throw ValidationError("Template '\(id)' not found. Run `asc app-shots templates list` to see available templates.")
        }
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [template],
            headers: ["ID", "Name", "Category", "Sizes", "Devices"],
            rowMapper: { [$0.id, $0.name, $0.category.rawValue, $0.supportedSizes.map(\.rawValue).joined(separator: ","), "\($0.deviceCount)"] }
        )
    }
}

// MARK: - ScreenSize ArgumentParser conformance

extension ScreenSize: @retroactive ExpressibleByArgument {}
