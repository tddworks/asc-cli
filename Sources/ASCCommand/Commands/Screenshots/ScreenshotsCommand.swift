import ArgumentParser
import Domain

struct ScreenshotsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "screenshots",
        abstract: "Manage App Store screenshots",
        subcommands: [ScreenshotsList.self]
    )
}

struct ScreenshotsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List screenshots in a screenshot set"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Screenshot set ID")
    var setId: String

    func run() async throws {
        let repo = try ClientProvider.makeScreenshotRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any ScreenshotRepository) async throws -> String {
        let screenshots = try await repo.listScreenshots(setId: setId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatItems(
            screenshots,
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
