import ArgumentParser
import ASCKit
import Foundation

struct IAPReviewScreenshotUpload: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "upload",
        abstract: "Upload (or replace) the App Store review screenshot for an in-app purchase"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "IAP ID")
    var iapId: String

    @Option(name: .long, help: "Path to image file")
    var file: String

    func run() async throws {
        let repo = try ClientProvider.makeInAppPurchaseReviewAssets()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any InAppPurchaseReviewAssets,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let url = URL(fileURLWithPath: file)
        let item = try await repo.uploadReviewScreenshot(iapId: iapId, fileURL: url)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([item], affordanceMode: affordanceMode)
    }
}
