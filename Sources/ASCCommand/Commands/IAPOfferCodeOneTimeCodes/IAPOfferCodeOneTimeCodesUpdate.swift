import ArgumentParser
import ASCKit

struct IAPOfferCodeOneTimeCodesUpdate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update an IAP one-time use code (activate/deactivate)"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "One-time code ID")
    var oneTimeCodeId: String

    @Option(name: .long, help: "Active status (true/false)")
    var active: String

    func run() async throws {
        let repo = try ClientProvider.makeInAppPurchaseOfferCodes()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any InAppPurchaseOfferCodes,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        guard let isActive = Bool(active) else {
            throw ValidationError("Invalid value '\(active)' for --active. Use: true, false")
        }
        let item = try await repo.updateOneTimeUseCode(oneTimeCodeId: oneTimeCodeId, isActive: isActive)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([item], affordanceMode: affordanceMode)
    }
}
