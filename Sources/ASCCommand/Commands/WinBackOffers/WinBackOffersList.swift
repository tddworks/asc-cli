import ArgumentParser
import ASCKit

struct WinBackOffersList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List win-back offers for a subscription"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Subscription ID")
    var subscriptionId: String

    func run() async throws {
        let repo = try ClientProvider.makeWinBackOffers()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any WinBackOffers,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let items = try await repo.listWinBackOffers(subscriptionId: subscriptionId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(items, affordanceMode: affordanceMode)
    }
}
