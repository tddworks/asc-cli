import ArgumentParser
import ASCKit

struct IAPOfferCodeCustomCodesList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List custom codes for an IAP offer code"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Offer code ID")
    var offerCodeId: String

    func run() async throws {
        let repo = try ClientProvider.makeInAppPurchaseOfferCodes()
        print(try await execute(repo: repo))
    }

    func execute(repo: any InAppPurchaseOfferCodes) async throws -> String {
        let items = try await repo.listCustomCodes(offerCodeId: offerCodeId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(items)
    }
}
