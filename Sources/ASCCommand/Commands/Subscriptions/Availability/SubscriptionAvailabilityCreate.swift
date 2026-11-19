import ArgumentParser
import ASCKit

struct SubscriptionAvailabilityCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create territory availability for a subscription"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Subscription ID to set availability for")
    var subscriptionId: String

    @Flag(name: .long, help: "Automatically make available in new territories Apple adds")
    var availableInNewTerritories: Bool = false

    @Option(name: .long, help: "Territory ID to include (e.g. USA, CHN, JPN). Repeat for multiple territories.")
    var territory: [String] = []

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionAvailabilities()
        print(try await execute(repo: repo))
    }

    func execute(repo: any SubscriptionAvailabilities) async throws -> String {
        let availability = try await repo.createAvailability(
            subscriptionId: subscriptionId,
            isAvailableInNewTerritories: availableInNewTerritories,
            territoryIds: territory
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [availability],
            headers: ["ID", "Subscription ID", "Available in New Territories", "Territories"],
            rowMapper: { [$0.id, $0.subscriptionId, String($0.isAvailableInNewTerritories), $0.territories.map(\.id).joined(separator: ", ")] }
        )
    }
}
