import ArgumentParser
import Domain

struct IAPReviewScreenshotDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete the review screenshot"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Review screenshot ID")
    var screenshotId: String

    func run() async throws {
        let repo = try ClientProvider.makeInAppPurchaseReviewRepository()
        try await execute(repo: repo)
    }

    func execute(repo: any InAppPurchaseReviewRepository) async throws {
        try await repo.deleteReviewScreenshot(screenshotId: screenshotId)
    }
}
