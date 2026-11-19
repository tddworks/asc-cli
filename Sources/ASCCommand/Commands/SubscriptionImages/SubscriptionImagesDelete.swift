import ArgumentParser
import ASCKit

struct SubscriptionImagesDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a subscription promotional image"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Image ID")
    var imageId: String

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionReviewAssets()
        try await execute(repo: repo)
    }

    func execute(repo: any SubscriptionReviewAssets) async throws {
        try await repo.deleteImage(imageId: imageId)
    }
}
