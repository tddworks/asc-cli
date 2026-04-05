import ArgumentParser
import Domain

struct SubscriptionOfferCodesList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List offer codes for a subscription"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Subscription ID")
    var subscriptionId: String

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionOfferCodeRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any SubscriptionOfferCodeRepository) async throws -> String {
        let items = try await repo.listOfferCodes(subscriptionId: subscriptionId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(items)
    }
}
