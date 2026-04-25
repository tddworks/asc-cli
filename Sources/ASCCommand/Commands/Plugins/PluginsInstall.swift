import ArgumentParser
import Domain

struct PluginsInstall: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "install",
        abstract: "Install a plugin from the marketplace"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Plugin name to install")
    var name: String

    func run() async throws {
        let repo = ClientProvider.makePluginRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any PluginRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let plugin = try await repo.install(name: name)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [plugin],
            headers: ["Name", "Version", "Author"],
            rowMapper: { [$0.name, $0.version, $0.author ?? "-"] },
            affordanceMode: affordanceMode
        )
    }
}
