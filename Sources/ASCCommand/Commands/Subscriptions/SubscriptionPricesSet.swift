import ArgumentParser
import Domain

struct SubscriptionPricesSet: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "set",
        abstract: "Set the per-territory price for a subscription"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Subscription ID")
    var subscriptionId: String

    @Option(name: .long, help: "Territory code (e.g. USA)")
    var territory: String

    @Option(name: .long, help: "Price point ID from `asc subscriptions price-points list`")
    var pricePointId: String

    @Option(name: .long, help: "Optional start date YYYY-MM-DD")
    var startDate: String?

    @Flag(name: .long, help: "Preserve current price during the transition")
    var preserveCurrentPrice: Bool = false

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionPriceRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any SubscriptionPriceRepository) async throws -> String {
        let preserveFlag: Bool? = preserveCurrentPrice ? true : nil
        let item = try await repo.setPrice(
            subscriptionId: subscriptionId,
            territory: territory,
            pricePointId: pricePointId,
            startDate: startDate,
            preserveCurrentPrice: preserveFlag
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [item],
            headers: ["ID", "Subscription ID"],
            rowMapper: { [$0.id, $0.subscriptionId] }
        )
    }
}
