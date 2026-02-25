import ArgumentParser
import Domain

struct BuildsUploadsGet: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get a build upload record by ID"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Build upload ID")
    var uploadId: String

    func run() async throws {
        let repo = try ClientProvider.makeBuildUploadRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any BuildUploadRepository) async throws -> String {
        let upload = try await repo.getBuildUpload(id: uploadId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [upload],
            headers: ["ID", "Version", "Build", "State"],
            rowMapper: { [$0.id, $0.version, $0.buildNumber, $0.state.rawValue] }
        )
    }
}
