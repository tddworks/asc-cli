import ArgumentParser
import ASCKit

struct IAPSubmit: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "submit",
        abstract: "Submit an in-app purchase for App Store review"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "IAP ID to submit for review")
    var iapId: String

    func run() async throws {
        let repo = try ClientProvider.makeInAppPurchaseSubmissionRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any InAppPurchaseSubmissionRepository) async throws -> String {
        let submission = try await repo.submitInAppPurchase(iapId: iapId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [submission],
            headers: ["ID", "IAP ID"],
            rowMapper: { [$0.id, $0.iapId] }
        )
    }
}
