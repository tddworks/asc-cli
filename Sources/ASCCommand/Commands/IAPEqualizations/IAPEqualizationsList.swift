import ArgumentParser
import Domain

struct IAPEqualizationsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List equalized territory prices for an IAP price point"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "IAP price point ID (from `asc iap price-points list`)")
    var pricePointId: String

    @Option(name: .long, help: "Maximum number of entries to return (default 200)")
    var limit: Int?

    func run() async throws {
        let repo = try ClientProvider.makeInAppPurchasePriceRepository()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any InAppPurchasePriceRepository,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let items = try await repo.listEqualizations(pricePointId: pricePointId, limit: limit)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(items, affordanceMode: affordanceMode)
    }
}
