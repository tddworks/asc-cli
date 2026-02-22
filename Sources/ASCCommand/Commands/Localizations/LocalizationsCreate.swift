import ArgumentParser
import Domain

struct LocalizationsCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a new App Store version localization"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App Store version ID")
    var versionId: String

    @Option(name: .long, help: "Locale identifier (e.g. en-US, zh-Hans)")
    var locale: String

    func run() async throws {
        let repo = try ClientProvider.makeScreenshotRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any ScreenshotRepository) async throws -> String {
        let created = try await repo.createLocalization(versionId: versionId, locale: locale)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [created],
            headers: ["ID", "Locale", "Version ID"],
            rowMapper: { [$0.id, $0.locale, $0.versionId] }
        )
    }
}
