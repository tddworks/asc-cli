import ArgumentParser
import Domain

struct SubscriptionAvailabilityGet: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get territory availability for a subscription"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Subscription ID to get availability for")
    var subscriptionId: String

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionAvailabilityRepository()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any SubscriptionAvailabilityRepository,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let availability = try await repo.getAvailability(subscriptionId: subscriptionId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [availability],
            headers: ["ID", "Subscription ID", "Available in New Territories", "Territories"],
            rowMapper: { [$0.id, $0.subscriptionId, String($0.isAvailableInNewTerritories), $0.territories.map(\.id).joined(separator: ", ")] },
            affordanceMode: affordanceMode
        )
    }
}
