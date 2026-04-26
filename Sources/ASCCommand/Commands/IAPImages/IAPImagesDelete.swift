import ArgumentParser
import Domain

struct IAPImagesDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a promotional image"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Image ID")
    var imageId: String

    func run() async throws {
        let repo = try ClientProvider.makeInAppPurchaseReviewRepository()
        try await execute(repo: repo)
    }

    func execute(repo: any InAppPurchaseReviewRepository) async throws {
        try await repo.deleteImage(imageId: imageId)
    }
}
