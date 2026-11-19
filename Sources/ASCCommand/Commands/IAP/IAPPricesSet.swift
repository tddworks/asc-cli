import ArgumentParser
import ASCKit

struct IAPPricesSet: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "set",
        abstract: "Set the price schedule for an in-app purchase"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "IAP ID")
    var iapId: String

    @Option(name: .long, help: "Base territory for pricing (e.g. USA)")
    var baseTerritory: String

    @Option(name: .long, help: "Price point ID from asc iap price-points list")
    var pricePointId: String

    func run() async throws {
        let repo = try ClientProvider.makeInAppPurchasePrices()
        print(try await execute(repo: repo))
    }

    func execute(repo: any InAppPurchasePrices) async throws -> String {
        let schedule = try await repo.setPriceSchedule(
            iapId: iapId,
            baseTerritory: baseTerritory,
            pricePointId: pricePointId
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [schedule],
            headers: ["Schedule ID", "IAP ID"],
            rowMapper: { [$0.id, $0.iapId] }
        )
    }
}
