import ArgumentParser
import Domain

struct IAPOfferCodeOneTimeCodesList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List one-time use codes for an IAP offer code"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Offer code ID")
    var offerCodeId: String

    func run() async throws {
        let repo = try ClientProvider.makeInAppPurchaseOfferCodeRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any InAppPurchaseOfferCodeRepository) async throws -> String {
        let items = try await repo.listOneTimeUseCodes(offerCodeId: offerCodeId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(items)
    }
}
