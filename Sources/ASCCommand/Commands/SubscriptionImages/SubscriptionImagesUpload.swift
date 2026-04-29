import ArgumentParser
import Domain
import Foundation

struct SubscriptionImagesUpload: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "upload",
        abstract: "Upload a promotional image for a subscription"
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
        let item = try await repo.uploadImage(subscriptionId: subscriptionId, fileURL: url)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([item], affordanceMode: affordanceMode)
    }
}
