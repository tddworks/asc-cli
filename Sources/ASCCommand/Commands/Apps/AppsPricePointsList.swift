import ArgumentParser
import ASCKit

struct AppsPricePointsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List the prices an app can be sold at in a territory (the 0 price makes it free)"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID")
    var appId: String

    @Option(name: .long, help: "Territory code (default: USA)")
    var territory: String = "USA"

    func run() async throws {
        let repo = try ClientProvider.makeAppPrices()
        print(try await execute(repo: repo))
    }

    func execute(repo: any AppPrices, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let points = try await repo.listPricePoints(appId: appId, territory: territory)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(points, affordanceMode: affordanceMode)
    }
}
