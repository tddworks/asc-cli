import ArgumentParser
import Domain

struct SubscriptionOffersList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List introductory offers for a subscription"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Subscription ID")
    var subscriptionId: String

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionIntroductoryOfferRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any SubscriptionIntroductoryOfferRepository) async throws -> String {
        let items = try await repo.listIntroductoryOffers(subscriptionId: subscriptionId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(items)
    }
}
