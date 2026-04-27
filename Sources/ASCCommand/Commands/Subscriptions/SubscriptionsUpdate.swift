import ArgumentParser
import Domain

extension SubscriptionPeriod: ExpressibleByArgument {}

struct SubscriptionsUpdate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update a subscription (name, family sharable, group level, review note)"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Subscription ID")
    var subscriptionId: String

    @Option(name: .long, help: "New display name")
    var name: String?

    @Flag(name: .long, help: "Mark as Family Sharable")
    var familySharable: Bool = false

    @Flag(name: .long, help: "Mark as not Family Sharable")
    var notFamilySharable: Bool = false

    @Option(name: .long, help: "Group level for upgrade/downgrade ordering")
    var groupLevel: Int?

    @Option(name: .long, help: "Billing period (ONE_WEEK, ONE_MONTH, TWO_MONTHS, THREE_MONTHS, SIX_MONTHS, ONE_YEAR)")
    var period: SubscriptionPeriod?

    @Option(name: .long, help: "App Review note")
    var reviewNote: String?

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any SubscriptionRepository) async throws -> String {
        let isFamilySharable: Bool? = familySharable ? true : (notFamilySharable ? false : nil)
        let item = try await repo.updateSubscription(
            subscriptionId: subscriptionId,
            name: name,
            isFamilySharable: isFamilySharable,
            groupLevel: groupLevel,
            subscriptionPeriod: period,
            reviewNote: reviewNote
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [item],
            headers: ["ID", "Name", "Product ID", "Period", "State"],
            rowMapper: { [$0.id, $0.name, $0.productId, $0.subscriptionPeriod.displayName, $0.state.rawValue] }
        )
    }
}
