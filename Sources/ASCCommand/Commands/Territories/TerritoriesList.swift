import ArgumentParser
import Domain

struct TerritoriesList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List all available App Store territories"
    )

    @OptionGroup var globals: GlobalOptions

    func run() async throws {
        let repo = try ClientProvider.makeTerritoryRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any TerritoryRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let territories = try await repo.listTerritories()
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            territories,
            headers: ["ID", "Currency"],
            rowMapper: { [$0.id, $0.currency ?? "—"] },
            affordanceMode: affordanceMode
        )
    }
}
