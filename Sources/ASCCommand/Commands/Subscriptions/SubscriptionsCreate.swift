import ArgumentParser
import Domain

struct SubscriptionsCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a new subscription in a group"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Subscription group ID")
    var groupId: String

    @Option(name: .long, help: "Display name for the subscription")
    var name: String

    @Option(name: .long, help: "Product ID (e.g. com.app.monthly)")
    var productId: String

    @Option(name: .long, help: "Billing period: ONE_WEEK, ONE_MONTH, TWO_MONTHS, THREE_MONTHS, SIX_MONTHS, ONE_YEAR")
    var period: String

    @Flag(name: .long, help: "Enable Family Sharing for this subscription")
    var familySharable: Bool = false

    @Option(name: .long, help: "Level within the group (used for upgrade/downgrade)")
    var groupLevel: Int?

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any SubscriptionRepository) async throws -> String {
        guard let subscriptionPeriod = SubscriptionPeriod(rawValue: period) else {
            throw ValidationError("Invalid period '\(period)'. Use: ONE_WEEK, ONE_MONTH, TWO_MONTHS, THREE_MONTHS, SIX_MONTHS, ONE_YEAR")
        }
        let item = try await repo.createSubscription(
            groupId: groupId,
            name: name,
            productId: productId,
            period: subscriptionPeriod,
            isFamilySharable: familySharable,
            groupLevel: groupLevel
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [item],
            headers: ["ID", "Name", "Product ID", "Period", "State"],
            rowMapper: { [$0.id, $0.name, $0.productId, $0.subscriptionPeriod.displayName, $0.state.rawValue] }
        )
    }
}
