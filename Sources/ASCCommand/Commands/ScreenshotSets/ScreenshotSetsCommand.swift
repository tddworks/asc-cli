import ArgumentParser
import Domain

struct ScreenshotSetsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "screenshot-sets",
        abstract: "Manage App Store screenshot sets",
        subcommands: [ScreenshotSetsList.self]
    )
}

struct ScreenshotSetsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List screenshot sets for an App Store version localization"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App Store version localization ID")
    var localizationId: String

    func run() async throws {
        let repo = try ClientProvider.makeScreenshotRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any ScreenshotRepository) async throws -> String {
        let sets = try await repo.listScreenshotSets(localizationId: localizationId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            sets,
            headers: ["ID", "Display Type", "Device", "Count"],
            rowMapper: { [$0.id, $0.displayTypeName, $0.deviceCategory.rawValue, "\($0.screenshotsCount)"] }
        )
    }
}
