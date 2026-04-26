import ArgumentParser
import Domain

struct SubscriptionPricePointsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List available price points for a subscription"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Subscription ID")
    var subscriptionId: String

    @Option(name: .long, help: "Filter by territory code (e.g. USA)")
    var territory: String?

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionPriceRepository()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any SubscriptionPriceRepository,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let items = try await repo.listPricePoints(subscriptionId: subscriptionId, territory: territory)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(items, affordanceMode: affordanceMode)
    }
}
