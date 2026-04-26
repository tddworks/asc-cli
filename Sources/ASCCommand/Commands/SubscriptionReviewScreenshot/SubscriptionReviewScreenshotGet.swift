import ArgumentParser
import Domain

struct SubscriptionReviewScreenshotGet: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Fetch the review screenshot for a subscription"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Subscription ID")
    var subscriptionId: String

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionReviewRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any SubscriptionReviewRepository) async throws -> String {
        let item = try await repo.getReviewScreenshot(subscriptionId: subscriptionId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(item.map { [$0] } ?? [])
    }
}
