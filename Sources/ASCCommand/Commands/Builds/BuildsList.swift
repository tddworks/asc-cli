import ArgumentParser
import Domain

struct BuildsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List builds"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Filter by app ID")
    var appId: String?

    @Option(name: .long, help: "Filter by platform (ios, macos, tvos, visionos)")
    var platform: String?

    @Option(name: .long, help: "Filter by version (e.g. 1.0.0)")
    var version: String?

    @Option(name: .long, help: "Maximum number of builds to return")
    var limit: Int?

    func run() async throws {
        let repo = try ClientProvider.makeBuildRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any BuildRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let platformFilter = platform.flatMap { BuildUploadPlatform(cliArgument: $0) }
        let response = try await repo.listBuilds(appId: appId, platform: platformFilter, version: version, limit: limit)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(response.data, affordanceMode: affordanceMode)
    }
}
