import ArgumentParser
import ASCKit

struct TerritoriesList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List all available App Store territories"
    )

    @OptionGroup var globals: GlobalOptions

    func run() async throws {
        let repo = try ClientProvider.makeTerritories()
        print(try await execute(repo: repo))
    }

    func execute(repo: any Territories, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let territories = try await repo.listTerritories()
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(territories, affordanceMode: affordanceMode)
    }
}
