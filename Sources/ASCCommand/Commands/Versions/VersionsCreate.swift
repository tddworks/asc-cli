import ArgumentParser
import Domain

struct VersionsCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a new App Store version"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID")
    var appId: String

    @Option(name: .long, help: "Version string (e.g. 1.2.3)")
    var version: String

    @Option(name: .long, help: "Platform: ios, macos, tvos, watchos, visionos")
    var platform: String

    func run() async throws {
        let repo = try ClientProvider.makeAppRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any AppRepository) async throws -> String {
        guard let appStorePlatform = AppStorePlatform(cliArgument: platform) else {
            throw ValidationError("Unknown platform '\(platform)'. Use: ios, macos, tvos, watchos, visionos")
        }
        let created = try await repo.createVersion(appId: appId, versionString: version, platform: appStorePlatform)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [created],
            headers: ["ID", "Platform", "Version", "State"],
            rowMapper: { [$0.id, $0.platform.displayName, $0.versionString, $0.state.displayName] }
        )
    }
}
