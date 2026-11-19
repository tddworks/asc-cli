import ArgumentParser
import ASCKit

struct VersionLocalizationsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "version-localizations",
        abstract: "Manage App Store version localizations",
        subcommands: [VersionLocalizationsList.self, VersionLocalizationsCreate.self, VersionLocalizationsUpdate.self]
    )
}

struct VersionLocalizationsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List localizations for an App Store version"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App Store version ID")
    var versionId: String

    func run() async throws {
        let repo = try ClientProvider.makeVersionLocalizations()
        print(try await execute(repo: repo))
    }

    func execute(repo: any VersionLocalizations, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let localizations = try await repo.listLocalizations(versionId: versionId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(localizations, affordanceMode: affordanceMode)
    }
}
