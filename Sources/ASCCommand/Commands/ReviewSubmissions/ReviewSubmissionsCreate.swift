import ArgumentParser
import ASCKit

struct ReviewSubmissionsCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Open a draft review submission for an app (reuses the open draft if there is one)"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID")
    var appId: String

    @Option(name: .long, help: "Platform: ios, macos, tvos, visionos")
    var platform: String = "ios"

    func run() async throws {
        let repo = try ClientProvider.makeSubmissionRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any SubmissionRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        guard let appStorePlatform = AppStorePlatform(cliArgument: platform) else {
            throw ValidationError("Unknown platform '\(platform)'. Use: ios, macos, tvos, visionos")
        }
        let submission = try await repo.createSubmission(appId: appId, platform: appStorePlatform)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([submission], affordanceMode: affordanceMode)
    }
}
