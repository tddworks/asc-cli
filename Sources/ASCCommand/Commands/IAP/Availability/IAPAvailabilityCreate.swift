import ArgumentParser
import Domain

struct IAPAvailabilityCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create territory availability for an in-app purchase"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "IAP ID to set availability for")
    var iapId: String

    @Flag(name: .long, help: "Automatically make available in new territories Apple adds")
    var availableInNewTerritories: Bool = false

    @Option(name: .long, help: "Territory ID to include (e.g. USA, CHN, JPN). Repeat for multiple territories.")
    var territory: [String] = []

    func run() async throws {
        let repo = try ClientProvider.makeInAppPurchaseAvailabilityRepository()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any InAppPurchaseAvailabilityRepository,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let availability = try await repo.createAvailability(
            iapId: iapId,
            isAvailableInNewTerritories: availableInNewTerritories,
            territoryIds: territory
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [availability],
            headers: ["ID", "IAP ID", "Available in New Territories", "Territories"],
            rowMapper: { [$0.id, $0.iapId, String($0.isAvailableInNewTerritories), $0.territories.map(\.id).joined(separator: ", ")] },
            affordanceMode: affordanceMode
        )
    }
}
