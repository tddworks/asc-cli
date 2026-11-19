import ArgumentParser
import ASCKit

struct AppClipExperienceLocalizationsCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a localization for a default experience"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Experience ID")
    var experienceId: String

    @Option(name: .long, help: "Locale code (e.g. en-US, fr-FR)")
    var locale: String

    @Option(name: .long, help: "Subtitle shown in the App Clip card")
    var subtitle: String?

    func run() async throws {
        let repo = try ClientProvider.makeAppClips()
        print(try await execute(repo: repo))
    }

    func execute(repo: any AppClips) async throws -> String {
        let localization = try await repo.createLocalization(experienceId: experienceId, locale: locale, subtitle: subtitle)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [localization],
            headers: ["ID", "Experience ID", "Locale", "Subtitle"],
            rowMapper: { [$0.id, $0.experienceId, $0.locale, $0.subtitle ?? ""] }
        )
    }
}
