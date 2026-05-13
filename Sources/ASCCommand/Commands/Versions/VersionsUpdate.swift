import ArgumentParser
import Domain

struct VersionsUpdate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update an App Store version's version string, copyright, or release schedule"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App Store version ID")
    var versionId: String

    @Option(name: .long, help: "New version string (e.g. 1.2.3)")
    var version: String?

    @Option(name: .long, help: "Copyright line shown on the App Store page (e.g. \"© 2026 Acme\")")
    var copyright: String?

    @Option(name: .long, help: "Release type: MANUAL, AFTER_APPROVAL, or SCHEDULED")
    var releaseType: String?

    @Option(name: .long, help: "ISO-8601 timestamp for SCHEDULED releases (e.g. 2026-06-01T00:00:00Z)")
    var earliestReleaseDate: String?

    func run() async throws {
        let repo = try ClientProvider.makeVersionRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any VersionRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let updated = try await repo.updateVersion(
            id: versionId,
            versionString: version,
            copyright: copyright,
            releaseType: releaseType,
            earliestReleaseDate: earliestReleaseDate
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [updated],
            headers: ["ID", "Platform", "Version", "State"],
            rowMapper: { [$0.id, $0.platform.displayName, $0.versionString, $0.state.displayName] },
            affordanceMode: affordanceMode
        )
    }
}
