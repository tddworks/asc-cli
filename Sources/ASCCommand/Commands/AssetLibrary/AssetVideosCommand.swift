import ArgumentParser
import Domain
import Foundation

struct AssetVideosCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "asset-videos",
        abstract: "Manage videos (app previews) in an app's asset library",
        subcommands: [AssetVideosList.self, AssetVideosUpload.self, AssetVideosUpdate.self, AssetVideosDelete.self]
    )
}

struct AssetVideosList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List videos in an asset library"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Asset library ID")
    var libraryId: String

    @Option(name: .long, help: "Show only this video")
    var videoId: String?

    @Option(name: .long, help: "Filter by state, e.g. AWAITING_UPLOAD, PREPARE_FOR_SUBMISSION, APPROVED")
    var state: LibraryAssetState?

    @Option(name: .long, help: "Filter by category: APP_SCREENSHOTS_AND_PREVIEWS or CREATIVE_ASSETS")
    var category: AssetCategory?

    func run() async throws {
        let repo = try ClientProvider.makeLibraryVideoRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any LibraryVideoRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let videos = try await repo.listVideos(libraryId: libraryId, videoId: videoId, state: state, category: category)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(videos, affordanceMode: affordanceMode)
    }
}

struct AssetVideosUpload: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "upload",
        abstract: "Upload a video into an asset library (reserve, upload, commit)"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Asset library ID")
    var libraryId: String

    @Option(name: .long, help: "Path to the video file")
    var file: String

    @Option(name: .long, help: "APP_SCREENSHOTS_AND_PREVIEWS (default) or CREATIVE_ASSETS — can't be changed later")
    var category: AssetCategory = .appScreenshotsAndPreviews

    @Option(name: .long, help: "A name to recognise the video by")
    var referenceName: String?

    @Option(name: .long, help: "Frame that represents the video, HH:MM:SS:FF (e.g. 00:00:03:00)")
    var previewFrameTimeCode: String?

    @Flag(name: .long, help: "Wait until App Store Connect has processed the video")
    var wait: Bool = false

    func run() async throws {
        let repo = try ClientProvider.makeLibraryVideoRepository()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any LibraryVideoRepository,
        affordanceMode: AffordanceMode = .cli,
        sleep: @Sendable (UInt64) async throws -> Void = { try await Task.sleep(nanoseconds: $0) }
    ) async throws -> String {
        var video = try await repo.uploadVideo(
            libraryId: libraryId, fileURL: URL(fileURLWithPath: file), category: category,
            referenceName: referenceName, previewFrameTimeCode: previewFrameTimeCode
        )
        if wait {
            video = try await AssetProcessingWait.untilProcessed(video, isPending: { $0.state.isAwaitingUpload || $0.state.isProcessing }, sleep: sleep) {
                try await repo.listVideos(libraryId: video.libraryId, videoId: video.id, state: nil, category: nil).first
            }
        }
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([video], affordanceMode: affordanceMode)
    }
}

struct AssetVideosUpdate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Rename a video, or archive it once approved"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Asset library ID")
    var libraryId: String

    @Option(name: .long, help: "Video ID")
    var videoId: String

    @Option(name: .long, help: "New reference name")
    var referenceName: String?

    @Option(name: .long, help: "true to archive (approved videos only)")
    var archived: Bool?

    func validate() throws {
        if referenceName == nil, archived == nil {
            throw ValidationError("Pass --reference-name and/or --archived")
        }
    }

    func run() async throws {
        let repo = try ClientProvider.makeLibraryVideoRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any LibraryVideoRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let video = try await repo.updateVideo(libraryId: libraryId, videoId: videoId, referenceName: referenceName, isArchived: archived)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([video], affordanceMode: affordanceMode)
    }
}

struct AssetVideosDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a video from its asset library (delete its placements first)"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Video ID")
    var videoId: String

    func run() async throws {
        let repo = try ClientProvider.makeLibraryVideoRepository()
        try await execute(repo: repo)
    }

    func execute(repo: any LibraryVideoRepository) async throws {
        try await repo.deleteVideo(videoId: videoId)
    }
}
