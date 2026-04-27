import ArgumentParser
import Domain

struct SubscriptionPricesSetBatch: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "set-batch",
        abstract: "Set multiple per-territory prices in a single call (mirrors iOS `setPrices(prices:)`)"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Subscription ID")
    var subscriptionId: String

    @Option(
        name: .long,
        help: "Repeatable territory=pricePointId pair, e.g. --price USA=spp-1 --price JPN=spp-2"
    )
    var price: [String] = []

    @Option(name: .long, help: "Optional shared start date YYYY-MM-DD applied to every entry")
    var startDate: String?

    @Flag(name: .long, help: "Preserve current price during the transition for every entry")
    var preserveCurrentPrice: Bool = false

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionPriceRepository()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any SubscriptionPriceRepository,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let inputs = try price.map { entry -> SubscriptionPriceInput in
            let parts = entry.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count == 2 else {
                throw ValidationError("--price must be `TERRITORY=PRICE_POINT_ID` (got `\(entry)`)")
            }
            return SubscriptionPriceInput(
                territory: parts[0],
                pricePointId: parts[1],
                startDate: startDate,
                preserveCurrentPrice: preserveCurrentPrice ? true : nil
            )
        }
        let schedule = try await repo.setPrices(subscriptionId: subscriptionId, prices: inputs)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([schedule], affordanceMode: affordanceMode)
    }
}
