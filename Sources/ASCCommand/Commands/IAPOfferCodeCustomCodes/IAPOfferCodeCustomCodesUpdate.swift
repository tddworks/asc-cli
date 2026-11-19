import ArgumentParser
import ASCKit

struct IAPOfferCodeCustomCodesUpdate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update an IAP custom code (activate/deactivate)"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Custom code ID")
    var customCodeId: String

    @Option(name: .long, help: "Active status (true/false)")
    var active: String

    func run() async throws {
        let repo = try ClientProvider.makeInAppPurchaseOfferCodes()
        print(try await execute(repo: repo))
    }

    func execute(repo: any InAppPurchaseOfferCodes) async throws -> String {
        guard let isActive = Bool(active) else {
            throw ValidationError("Invalid value '\(active)' for --active. Use: true, false")
        }
        let item = try await repo.updateCustomCode(customCodeId: customCodeId, isActive: isActive)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [item],
            headers: ["ID", "Custom Code", "Codes", "Expiration", "Active"],
            rowMapper: { [$0.id, $0.customCode, String($0.numberOfCodes), $0.expirationDate ?? "", String($0.isActive)] }
        )
    }
}
