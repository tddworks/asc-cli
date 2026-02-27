import ArgumentParser
import Domain
import Foundation

struct AppPreviewsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "app-previews",
        abstract: "Manage App Store app preview videos",
        subcommands: [AppPreviewsList.self, AppPreviewsUpload.self]
    )
}

struct AppPreviewsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List app previews in a preview set"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App preview set ID")
    var setId: String

    func run() async throws {
        let repo = try ClientProvider.makePreviewRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any PreviewRepository) async throws -> String {
        let previews = try await repo.listPreviews(setId: setId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            previews,
            headers: ["ID", "File Name", "Size", "Asset State", "Video State"],
            rowMapper: {
                [
                    $0.id,
                    $0.fileName,
                    $0.fileSizeDescription,
                    $0.assetDeliveryState?.displayName ?? "-",
                    $0.videoDeliveryState?.displayName ?? "-",
                ]
            }
        )
    }
}

struct AppPreviewsUpload: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "upload",
        abstract: "Upload a video file to an app preview set"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App preview set ID")
    var setId: String

    @Option(name: .long, help: "Path to video file (.mp4, .mov, .m4v)")
    var file: String

    @Option(name: .long, help: "Preview frame timecode (e.g. 00:00:05)")
    var previewFrameTimeCode: String?

    func run() async throws {
        let repo = try ClientProvider.makePreviewRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any PreviewRepository) async throws -> String {
        let fileURL = URL(fileURLWithPath: file)
        let preview = try await repo.uploadPreview(
            setId: setId,
            fileURL: fileURL,
            previewFrameTimeCode: previewFrameTimeCode
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [preview],
            headers: ["ID", "File Name", "Size", "Asset State", "Video State"],
            rowMapper: {
                [
                    $0.id,
                    $0.fileName,
                    $0.fileSizeDescription,
                    $0.assetDeliveryState?.displayName ?? "-",
                    $0.videoDeliveryState?.displayName ?? "-",
                ]
            }
        )
    }
}
