import ArgumentParser
import ASCKit

struct SubscriptionsSubmit: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "submit",
        abstract: "Submit a subscription for App Store review"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Subscription ID to submit for review")
    var subscriptionId: String

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionSubmissions()
        print(try await execute(repo: repo))
    }

    func execute(repo: any SubscriptionSubmissions) async throws -> String {
        let submission = try await repo.submitSubscription(subscriptionId: subscriptionId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [submission],
            headers: ["ID", "Subscription ID"],
            rowMapper: { [$0.id, $0.subscriptionId] }
        )
    }
}
