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
        let screenshots = try await repo.listScreenshots(setId: setId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)

        let output = try formatter.formatItems(
            screenshots,
            headers: ["ID", "File Name", "Size", "Dimensions", "State"],
            rowMapper: { screenshot in
                [
                    screenshot.id,
                    screenshot.fileName,
                    screenshot.fileSizeDescription,
                    screenshot.dimensionsDescription ?? "-",
                    screenshot.assetState?.displayName ?? "-",
                ]
            }
        )
        print(output)
    }
}
