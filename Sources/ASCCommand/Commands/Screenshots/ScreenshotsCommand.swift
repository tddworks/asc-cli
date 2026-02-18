import ArgumentParser
import Domain

struct ScreenshotsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "screenshots",
        abstract: "Manage App Store screenshots",
        subcommands: [ScreenshotSetsList.self, ScreenshotsList.self]
    )
}

struct ScreenshotSetsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "sets",
        abstract: "List screenshot sets for an App Store version localization"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App Store version localization ID")
    var localization: String

    func run() async throws {
        let repo = try ClientProvider.makeScreenshotRepository()
        let sets = try await repo.listScreenshotSets(localizationId: localization)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)

        let output = try formatter.formatItems(
            sets,
            headers: ["ID", "Display Type", "Device", "Count"],
            rowMapper: { set in
                [set.id, set.displayTypeName, set.deviceCategory.rawValue, "\(set.screenshotsCount)"]
            }
        )
        print(output)
    }
}

struct ScreenshotsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List screenshots in a screenshot set"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Screenshot set ID")
    var set: String

    func run() async throws {
        let repo = try ClientProvider.makeScreenshotRepository()
        let screenshots = try await repo.listScreenshots(setId: set)
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
