import ArgumentParser
import Domain

struct VersionsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "versions",
        abstract: "Manage App Store versions",
        subcommands: [VersionsList.self]
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
        let versions = try await repo.listVersions(appId: appId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)

        let output = try formatter.formatAgentItems(
            versions,
            headers: ["ID", "Platform", "Version", "State", "Live"],
            rowMapper: { version in
                [
                    version.id,
                    version.platform.displayName,
                    version.versionString,
                    version.state.displayName,
                    version.isLive ? "yes" : "no",
                ]
            }
        )
        print(output)
    }
}
