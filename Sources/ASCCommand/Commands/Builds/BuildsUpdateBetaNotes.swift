import ArgumentParser
import Domain

struct BuildsUpdateBetaNotes: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update-beta-notes",
        abstract: "Set TestFlight 'What's New' notes for a build locale"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Build ID")
    var buildId: String

    @Option(name: .long, help: "Locale (e.g. en-US)")
    var locale: String

    @Option(name: .long, help: "What's new notes text")
    var notes: String

    func run() async throws {
        let repo = try ClientProvider.makeBetaBuildLocalizationRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any BetaBuildLocalizationRepository) async throws -> String {
        let loc = try await repo.upsertBetaBuildLocalization(buildId: buildId, locale: locale, whatsNew: notes)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [loc],
            headers: ["ID", "Locale", "What's New"],
            rowMapper: { [$0.id, $0.locale, $0.whatsNew ?? ""] }
        )
    }
}
