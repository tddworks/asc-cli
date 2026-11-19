import ArgumentParser
import ASCKit

struct VersionLocalizationsUpdate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update text content for an App Store version localization"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App Store version localization ID")
    var localizationId: String

    @Option(name: .long, help: "What's New text (release notes)")
    var whatsNew: String?

    @Option(name: .long, help: "App description")
    var description: String?

    @Option(name: .long, help: "Keywords (comma-separated)")
    var keywords: String?

    @Option(name: .long, help: "Marketing URL")
    var marketingUrl: String?

    @Option(name: .long, help: "Support URL")
    var supportUrl: String?

    @Option(name: .long, help: "Promotional text")
    var promotionalText: String?

    func run() async throws {
        let repo = try ClientProvider.makeVersionLocalizationRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any VersionLocalizationRepository) async throws -> String {
        let updated = try await repo.updateLocalization(
            localizationId: localizationId,
            whatsNew: whatsNew,
            description: description,
            keywords: keywords,
            marketingUrl: marketingUrl,
            supportUrl: supportUrl,
            promotionalText: promotionalText
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [updated],
            headers: ["ID", "Locale", "What's New"],
            rowMapper: { [$0.id, $0.locale, $0.whatsNew ?? "-"] }
        )
    }
}
