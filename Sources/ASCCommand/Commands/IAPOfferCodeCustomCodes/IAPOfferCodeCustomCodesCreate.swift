import ArgumentParser
import ASCKit

struct IAPOfferCodeCustomCodesCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a custom code for an IAP offer code"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Offer code ID")
    var offerCodeId: String

    @Option(name: .long, help: "Custom code string")
    var customCode: String

    @Option(name: .long, help: "Number of codes to generate")
    var numberOfCodes: Int

    @Option(name: .long, help: "Expiration date in YYYY-MM-DD format — optional")
    var expirationDate: String?

    func run() async throws {
        let repo = try ClientProvider.makeInAppPurchaseOfferCodeRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any InAppPurchaseOfferCodeRepository) async throws -> String {
        let item = try await repo.createCustomCode(
            offerCodeId: offerCodeId,
            customCode: customCode,
            numberOfCodes: numberOfCodes,
            expirationDate: expirationDate
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [item],
            headers: ["ID", "Custom Code", "Codes", "Expiration", "Active"],
            rowMapper: { [$0.id, $0.customCode, String($0.numberOfCodes), $0.expirationDate ?? "", String($0.isActive)] }
        )
    }
}
