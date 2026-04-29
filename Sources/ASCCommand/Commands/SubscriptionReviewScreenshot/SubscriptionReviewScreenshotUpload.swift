import ArgumentParser
import Domain
import Foundation

struct SubscriptionReviewScreenshotUpload: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "upload",
        abstract: "Upload (or replace) the App Store review screenshot for a subscription"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Subscription ID")
    var subscriptionId: String

    @Option(name: .long, help: "Path to image file")
    var file: String

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionReviewRepository()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any SubscriptionReviewRepository,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let url = URL(fileURLWithPath: file)
        let item = try await repo.uploadReviewScreenshot(subscriptionId: subscriptionId, fileURL: url)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([item], affordanceMode: affordanceMode)
    }
}
