import ArgumentParser
import Domain

struct SubscriptionOfferCodesPricesList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List per-territory prices for a subscription offer code"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Offer code ID")
    var offerCodeId: String

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionOfferCodeRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any SubscriptionOfferCodeRepository) async throws -> String {
        let items = try await repo.listPrices(offerCodeId: offerCodeId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(items)
    }
}
