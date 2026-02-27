import ArgumentParser
import Domain

struct SubscriptionsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List subscriptions in a subscription group"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Subscription group ID")
    var groupId: String

    @Option(name: .long, help: "Maximum number of results")
    var limit: Int?

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any SubscriptionRepository) async throws -> String {
        let response = try await repo.listSubscriptions(groupId: groupId, limit: limit)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            response.data,
            headers: ["ID", "Name", "Product ID", "Period", "State"],
            rowMapper: { [$0.id, $0.name, $0.productId, $0.subscriptionPeriod.displayName, $0.state.rawValue] }
        )
    }
}
