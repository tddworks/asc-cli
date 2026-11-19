import ArgumentParser
import ASCKit

struct AppsPricesSet: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "set",
        abstract: "Set an app's price from a base-territory price point; Apple equalizes the other territories"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID")
    var appId: String

    @Option(name: .long, help: "Base territory code, e.g. USA")
    var baseTerritory: String

    @Option(name: .long, help: "Price point ID in the base territory (from `asc apps price-points list`)")
    var pricePointId: String

    func run() async throws {
        let repo = try ClientProvider.makeAppPrices()
        print(try await execute(repo: repo))
    }

    func execute(repo: any AppPrices, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let schedule = try await repo.setPriceSchedule(appId: appId, baseTerritory: baseTerritory, pricePointId: pricePointId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([schedule], affordanceMode: affordanceMode)
    }
}
