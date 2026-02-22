import ArgumentParser
import Domain
import Foundation

struct ScreenshotsUpload: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "upload",
        abstract: "Upload a screenshot to a screenshot set"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Screenshot set ID")
    var setId: String

    @Option(name: .long, help: "Path to the image file")
    var file: String

    func run() async throws {
        let repo = try ClientProvider.makeScreenshotRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any ScreenshotRepository) async throws -> String {
        let fileURL = URL(fileURLWithPath: file)
        let screenshot = try await repo.uploadScreenshot(setId: setId, fileURL: fileURL)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatItems(
            [screenshot],
            headers: ["ID", "File Name", "Size", "Dimensions", "State"],
            rowMapper: { [
                $0.id,
                $0.fileName,
                $0.fileSizeDescription,
                $0.dimensionsDescription ?? "-",
                $0.assetState?.displayName ?? "-",
            ] }
        )
    }
}
