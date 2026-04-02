import ArgumentParser
import Domain

struct PluginsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List installed plugins"
    )

    @OptionGroup var globals: GlobalOptions

    func run() async throws {
        let repo = ClientProvider.makePluginRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any PluginRepository) async throws -> String {
        let plugins = try await repo.listInstalled()
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            plugins,
            headers: ["Name", "Version", "Slug"],
            rowMapper: { [$0.name, $0.version, $0.slug] }
        )
    }
}
