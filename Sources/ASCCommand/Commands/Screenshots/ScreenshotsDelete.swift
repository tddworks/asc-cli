import ArgumentParser
import Domain

struct ScreenshotsDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a screenshot from its screenshot set"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Screenshot ID")
    var screenshotId: String

    func run() async throws {
        let repo = try ClientProvider.makeScreenshotRepository()
        try await execute(repo: repo)
    }

    func execute(repo: any ScreenshotRepository) async throws {
        try await repo.deleteScreenshot(screenshotId: screenshotId)
    }
}
