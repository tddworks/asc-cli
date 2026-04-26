import ArgumentParser
import Domain

struct SubscriptionPromotionalOffersPricesList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List per-territory prices for a promotional offer"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Promotional offer ID")
    var offerId: String

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionPromotionalOfferRepository()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any SubscriptionPromotionalOfferRepository,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let items = try await repo.listPrices(offerId: offerId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(items, affordanceMode: affordanceMode)
    }
}
