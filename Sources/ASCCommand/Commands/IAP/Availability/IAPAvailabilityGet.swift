import ArgumentParser
import Domain

struct IAPAvailabilityGet: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get territory availability for an in-app purchase"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "IAP ID to get availability for")
    var iapId: String

    func run() async throws {
        let repo = try ClientProvider.makeInAppPurchaseAvailabilityRepository()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any InAppPurchaseAvailabilityRepository,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let availability = try await repo.getAvailability(iapId: iapId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [availability],
            headers: ["ID", "IAP ID", "Available in New Territories", "Territories"],
            rowMapper: { [$0.id, $0.iapId, String($0.isAvailableInNewTerritories), $0.territories.map(\.id).joined(separator: ", ")] },
            affordanceMode: affordanceMode
        )
    }
}
