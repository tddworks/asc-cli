import ArgumentParser
import Domain

struct WinBackOffersPricesList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List per-territory prices for a win-back offer"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Win-back offer ID")
    var offerId: String

    func run() async throws {
        let repo = try ClientProvider.makeWinBackOfferRepository()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any WinBackOfferRepository,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let items = try await repo.listPrices(offerId: offerId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(items, affordanceMode: affordanceMode)
    }
}
