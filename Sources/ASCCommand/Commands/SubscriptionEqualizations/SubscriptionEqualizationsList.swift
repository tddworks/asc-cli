import ArgumentParser
import Domain

struct SubscriptionEqualizationsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List equalized territory prices for a subscription price point"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Subscription price point ID (from `asc subscriptions price-points list`)")
    var pricePointId: String

    @Option(name: .long, help: "Maximum number of entries to return (default 200)")
    var limit: Int?

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionPriceRepository()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any SubscriptionPriceRepository,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let items = try await repo.listEqualizations(pricePointId: pricePointId, limit: limit)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(items, affordanceMode: affordanceMode)
    }
}
