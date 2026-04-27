import ArgumentParser
import Domain

struct IAPPricePointsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List available price points for an in-app purchase"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "IAP ID")
    var iapId: String

    @Option(name: .long, help: "Filter by territory code (e.g. USA)")
    var territory: String?

    func run() async throws {
        let repo = try ClientProvider.makeInAppPurchasePriceRepository()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any InAppPurchasePriceRepository,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let items = try await repo.listPricePoints(iapId: iapId, territory: territory)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(items, affordanceMode: affordanceMode)
    }
}
