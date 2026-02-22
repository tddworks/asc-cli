import ArgumentParser
import Domain

struct LocalizationsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "localizations",
        abstract: "Manage App Store version localizations",
        subcommands: [LocalizationsList.self, LocalizationsCreate.self]
    )
}

struct LocalizationsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List localizations for an App Store version"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App Store version ID")
    var versionId: String

    func run() async throws {
        let repo = try ClientProvider.makeScreenshotRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any ScreenshotRepository) async throws -> String {
        let localizations = try await repo.listLocalizations(versionId: versionId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            localizations,
            headers: ["ID", "Locale"],
            rowMapper: { [$0.id, $0.locale] }
        )
    }
}
