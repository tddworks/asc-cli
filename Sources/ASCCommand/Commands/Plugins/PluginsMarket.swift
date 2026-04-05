import ArgumentParser
import Domain

struct PluginsMarket: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "market",
        abstract: "Browse the plugin marketplace",
        subcommands: [
            MarketList.self,
            MarketSearch.self,
        ],
        defaultSubcommand: MarketList.self
    )
}

struct MarketList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List all available plugins in the marketplace"
    )

    @OptionGroup var globals: GlobalOptions

    func run() async throws {
        let repo = ClientProvider.makePluginRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any PluginRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let plugins = try await repo.listAvailable()
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            plugins,
            headers: ["Name", "Version", "Author", "Installed"],
            rowMapper: { [$0.name, $0.version, $0.author ?? "-", $0.isInstalled ? "yes" : "no"] },
            affordanceMode: affordanceMode
        )
    }
}

struct MarketSearch: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "search",
        abstract: "Search plugins in the marketplace"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Search query")
    var query: String

    func run() async throws {
        let repo = ClientProvider.makePluginRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any PluginRepository) async throws -> String {
        let plugins = try await repo.searchAvailable(query: query)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            plugins,
            headers: ["Name", "Version", "Author", "Installed"],
            rowMapper: { [$0.name, $0.version, $0.author ?? "-", $0.isInstalled ? "yes" : "no"] }
        )
    }
}
