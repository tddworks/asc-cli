import ArgumentParser
import ASCKit

struct ScreenshotSetsDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a screenshot set and every screenshot in it"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Screenshot set ID")
    var setId: String

    func run() async throws {
        let repo = try ClientProvider.makeAppScreenshots()
        try await execute(repo: repo)
    }

    func execute(repo: any AppScreenshots) async throws {
        try await repo.deleteScreenshotSet(setId: setId)
    }
}
