import ArgumentParser
import ASCKit

struct AppAvailabilityCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Set up where an app is available (App Store Connect's \"Set Up Availability\")"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID")
    var appId: String

    @Option(name: .long, help: "Territory to make the app available in (e.g. USA). Repeat for several.")
    var territory: [String] = []

    @Flag(name: .long, help: "Make the app available in every territory Apple sells in (`asc territories list`)")
    var allTerritories: Bool = false

    @Flag(name: .long, help: "Automatically make the app available in territories Apple adds later")
    var availableInNewTerritories: Bool = false

    func run() async throws {
        print(try await execute(
            repo: try ClientProvider.makeAppAvailabilityRepository(),
            territoryRepo: try ClientProvider.makeTerritoryRepository()
        ))
    }

    func execute(
        repo: any AppAvailabilityRepository,
        territoryRepo: any TerritoryRepository,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        guard allTerritories != !territory.isEmpty else {
            throw ValidationError("Pass either --territory (one or more) or --all-territories")
        }
        let territoryIds = allTerritories ? try await territoryRepo.listTerritories().map(\.id) : territory
        let availability = try await repo.createAppAvailability(
            appId: appId, isAvailableInNewTerritories: availableInNewTerritories, territoryIds: territoryIds
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([availability], affordanceMode: affordanceMode)
    }
}
