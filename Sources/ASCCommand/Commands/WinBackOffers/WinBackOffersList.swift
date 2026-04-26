import ArgumentParser
import Domain

struct WinBackOffersList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List win-back offers for a subscription"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Subscription ID")
    var subscriptionId: String

    func run() async throws {
        let repo = try ClientProvider.makeWinBackOfferRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any WinBackOfferRepository) async throws -> String {
        let items = try await repo.listWinBackOffers(subscriptionId: subscriptionId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(items)
    }
}
