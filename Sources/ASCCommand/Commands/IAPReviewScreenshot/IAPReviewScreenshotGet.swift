import ArgumentParser
import ASCKit

struct IAPReviewScreenshotGet: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Fetch the review screenshot for an in-app purchase"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "IAP ID")
    var iapId: String

    func run() async throws {
        let repo = try ClientProvider.makeInAppPurchaseReviewAssets()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any InAppPurchaseReviewAssets,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let item = try await repo.getReviewScreenshot(iapId: iapId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(item.map { [$0] } ?? [], affordanceMode: affordanceMode)
    }
}
