import ArgumentParser
import Domain

struct BuildsNextNumber: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "next-number",
        abstract: "Get the next build number for a version"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID (required)")
    var appId: String

    @Option(name: .long, help: "Version string (e.g. 1.0.0)")
    var version: String

    @Option(name: .long, help: "Platform (ios, macos, tvos, visionos)")
    var platform: String

    func run() async throws {
        let repo = try ClientProvider.makeBuildRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any BuildRepository) async throws -> String {
        guard let platformValue = BuildUploadPlatform(cliArgument: platform) else {
            throw ValidationError("Invalid platform '\(platform)'. Use: ios, macos, tvos, visionos")
        }

        let response = try await repo.listBuilds(appId: appId, platform: platformValue, version: version, limit: nil)
        let result = NextBuildNumber.compute(appId: appId, version: version, platform: platformValue, builds: response.data)

        // Plain number by default (for scripting); full JSON with affordances when --pretty
        if globals.pretty {
            let formatter = OutputFormatter(format: .json, pretty: true)
            return try formatter.format(SingleDataResponse(data: WithAffordances(result)))
        }
        return "\(result.nextBuildNumber)"
    }
}
