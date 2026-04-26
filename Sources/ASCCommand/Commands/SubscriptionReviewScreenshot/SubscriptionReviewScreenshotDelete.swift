import ArgumentParser
import Domain

struct SubscriptionReviewScreenshotDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete the subscription review screenshot"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Review screenshot ID")
    var screenshotId: String

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionReviewRepository()
        try await execute(repo: repo)
    }

    func execute(repo: any SubscriptionReviewRepository) async throws {
        try await repo.deleteReviewScreenshot(screenshotId: screenshotId)
    }
}
