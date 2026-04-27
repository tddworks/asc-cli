import ArgumentParser
import Domain

struct SubscriptionImagesDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a subscription promotional image"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Image ID")
    var imageId: String

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionReviewRepository()
        try await execute(repo: repo)
    }

    func execute(repo: any SubscriptionReviewRepository) async throws {
        try await repo.deleteImage(imageId: imageId)
    }
}
