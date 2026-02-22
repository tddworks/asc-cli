import ArgumentParser
import Domain

struct VersionsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "versions",
        abstract: "Manage App Store versions",
        subcommands: [VersionsList.self, VersionsCreate.self, VersionsSubmit.self]
    )
}

struct VersionsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List App Store versions for an app (one per platform: iOS, macOS, tvOS, …)"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID")
    var appId: String

    func run() async throws {
        let repo = try ClientProvider.makeAppRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any AppRepository) async throws -> String {
        let versions = try await repo.listVersions(appId: appId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            versions,
            headers: ["ID", "Platform", "Version", "State", "Live"],
            rowMapper: { [
                $0.id,
                $0.platform.displayName,
                $0.versionString,
                $0.state.displayName,
                $0.isLive ? "yes" : "no",
            ] }
        )
    }
}
