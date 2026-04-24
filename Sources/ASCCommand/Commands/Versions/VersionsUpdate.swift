import ArgumentParser
import Domain

struct VersionsUpdate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update an existing App Store version's version string"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App Store version ID")
    var versionId: String

    @Option(name: .long, help: "New version string (e.g. 1.2.3)")
    var version: String

    func run() async throws {
        let repo = try ClientProvider.makeVersionRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any VersionRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let updated = try await repo.updateVersion(id: versionId, versionString: version)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [updated],
            headers: ["ID", "Platform", "Version", "State"],
            rowMapper: { [$0.id, $0.platform.displayName, $0.versionString, $0.state.displayName] },
            affordanceMode: affordanceMode
        )
    }
}
