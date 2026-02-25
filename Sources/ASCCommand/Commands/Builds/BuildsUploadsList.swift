import ArgumentParser
import Domain

struct BuildsUploadsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List build upload records for an app"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID")
    var appId: String

    func run() async throws {
        let repo = try ClientProvider.makeBuildUploadRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any BuildUploadRepository) async throws -> String {
        let uploads = try await repo.listBuildUploads(appId: appId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            uploads,
            headers: ["ID", "Version", "Build", "State"],
            rowMapper: { [$0.id, $0.version, $0.buildNumber, $0.state.rawValue] }
        )
    }
}
