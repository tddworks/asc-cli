import ArgumentParser
import Domain

struct PluginsUpdate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update an installed plugin to the latest marketplace version"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Plugin name (matches `Plugin.name` from `asc plugins list`)")
    var name: String

    func run() async throws {
        let repo = ClientProvider.makePluginRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any PluginRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let plugin = try await repo.update(name: name)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [plugin],
            headers: ["Name", "Version", "Author"],
            rowMapper: { [$0.name, $0.version, $0.author ?? "-"] },
            affordanceMode: affordanceMode
        )
    }
}
