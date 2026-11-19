import ArgumentParser
import ASCKit

struct SubscriptionImagesList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List promotional images for a subscription"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Subscription ID")
    var subscriptionId: String

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionReviewAssets()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any SubscriptionReviewAssets,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let items = try await repo.listImages(subscriptionId: subscriptionId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(items, affordanceMode: affordanceMode)
    }
}
