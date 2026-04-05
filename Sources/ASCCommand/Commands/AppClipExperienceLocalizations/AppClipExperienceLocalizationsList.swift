import ArgumentParser
import Domain

struct AppClipExperienceLocalizationsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List localizations for a default experience"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Experience ID")
    var experienceId: String

    func run() async throws {
        let repo = try ClientProvider.makeAppClipRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any AppClipRepository) async throws -> String {
        let localizations = try await repo.listLocalizations(experienceId: experienceId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(localizations)
    }
}
