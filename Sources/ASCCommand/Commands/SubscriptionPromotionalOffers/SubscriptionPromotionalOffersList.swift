import ArgumentParser
import Domain

struct SubscriptionPromotionalOffersList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List promotional offers for a subscription"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Subscription ID")
    var subscriptionId: String

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionPromotionalOfferRepository()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any SubscriptionPromotionalOfferRepository,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let items = try await repo.listPromotionalOffers(subscriptionId: subscriptionId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(items, affordanceMode: affordanceMode)
    }
}
