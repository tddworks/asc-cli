import ArgumentParser
import ASCKit

struct SubscriptionsDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a subscription"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Subscription ID")
    var subscriptionId: String

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptions()
        try await execute(repo: repo)
    }

    func execute(repo: any Subscriptions) async throws {
        try await repo.deleteSubscription(subscriptionId: subscriptionId)
    }
}
