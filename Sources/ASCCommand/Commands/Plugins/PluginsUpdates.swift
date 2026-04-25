import ArgumentParser
import Domain

struct PluginsUpdates: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "updates",
        abstract: "List installed plugins that have a newer version available"
    )

    @OptionGroup var globals: GlobalOptions

    func run() async throws {
        let repo = ClientProvider.makePluginRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any PluginRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let updates = try await repo.listOutdated()
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            updates,
            headers: ["Name", "Installed", "Latest"],
            rowMapper: { [$0.name, $0.installedVersion, $0.latestVersion] },
            affordanceMode: affordanceMode
        )
    }
}
