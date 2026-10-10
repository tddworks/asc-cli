import ArgumentParser
import Domain
import Foundation

struct AssetImagesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "asset-images",
        abstract: "Manage images in an app's asset library",
        subcommands: [AssetImagesList.self, AssetImagesUpload.self, AssetImagesUpdate.self, AssetImagesDelete.self]
    )
}

struct AssetImagesList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List images in an asset library"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Asset library ID")
    var libraryId: String

    @Option(name: .long, help: "Show only this image")
    var imageId: String?

    @Option(name: .long, help: "Filter by state, e.g. AWAITING_UPLOAD, PREPARE_FOR_SUBMISSION, APPROVED")
    var state: LibraryAssetState?

    @Option(name: .long, help: "Filter by category: APP_SCREENSHOTS_AND_PREVIEWS or CREATIVE_ASSETS")
    var category: AssetCategory?

    func run() async throws {
        let repo = try ClientProvider.makeLibraryImageRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any LibraryImageRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let images = try await repo.listImages(libraryId: libraryId, imageId: imageId, state: state, category: category)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(images, affordanceMode: affordanceMode)
    }
}

struct AssetImagesUpload: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "upload",
        abstract: "Upload an image into an asset library (reserve, upload, commit)"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Asset library ID")
    var libraryId: String

    @Option(name: .long, help: "Path to the image file")
    var file: String

    @Option(name: .long, help: "APP_SCREENSHOTS_AND_PREVIEWS (default) or CREATIVE_ASSETS — can't be changed later")
    var category: AssetCategory = .appScreenshotsAndPreviews

    @Option(name: .long, help: "A name to recognise the image by")
    var referenceName: String?

    @Flag(name: .long, help: "Wait until App Store Connect has processed the image")
    var wait: Bool = false

    func run() async throws {
        let repo = try ClientProvider.makeLibraryImageRepository()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any LibraryImageRepository,
        affordanceMode: AffordanceMode = .cli,
        sleep: @Sendable (UInt64) async throws -> Void = { try await Task.sleep(nanoseconds: $0) }
    ) async throws -> String {
        var image = try await repo.uploadImage(
            libraryId: libraryId, fileURL: URL(fileURLWithPath: file), category: category, referenceName: referenceName
        )
        if wait {
            image = try await AssetProcessingWait.untilProcessed(image, isPending: { $0.state.isAwaitingUpload || $0.state.isProcessing }, sleep: sleep) {
                try await repo.listImages(libraryId: image.libraryId, imageId: image.id, state: nil, category: nil).first
            }
        }
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([image], affordanceMode: affordanceMode)
    }
}

struct AssetImagesUpdate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Rename an image, or archive it once approved"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Asset library ID")
    var libraryId: String

    @Option(name: .long, help: "Image ID")
    var imageId: String

    @Option(name: .long, help: "New reference name")
    var referenceName: String?

    @Option(name: .long, help: "true to archive (approved images only)")
    var archived: Bool?

    func validate() throws {
        if referenceName == nil, archived == nil {
            throw ValidationError("Pass --reference-name and/or --archived")
        }
    }

    func run() async throws {
        let repo = try ClientProvider.makeLibraryImageRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any LibraryImageRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let image = try await repo.updateImage(libraryId: libraryId, imageId: imageId, referenceName: referenceName, isArchived: archived)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([image], affordanceMode: affordanceMode)
    }
}

struct AssetImagesDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete an image from its asset library (delete its placements first)"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Image ID")
    var imageId: String

    func run() async throws {
        let repo = try ClientProvider.makeLibraryImageRepository()
        try await execute(repo: repo)
    }

    func execute(repo: any LibraryImageRepository) async throws {
        try await repo.deleteImage(imageId: imageId)
    }
}
