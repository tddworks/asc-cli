import ArgumentParser
import Domain

struct IAPPriceScheduleGet: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get the current price schedule for an in-app purchase"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "IAP ID")
    var iapId: String

    func run() async throws {
        let repo = try ClientProvider.makeInAppPurchasePriceRepository()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any InAppPurchasePriceRepository,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let schedule = try await repo.getPriceSchedule(iapId: iapId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(schedule.map { [$0] } ?? [], affordanceMode: affordanceMode)
    }
}
