import ArgumentParser
import Domain

struct VersionsSubmit: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "submit",
        abstract: "Submit an App Store version for review"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App Store Version ID")
    var versionId: String

    func run() async throws {
        let repo = try ClientProvider.makeSubmissionRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any SubmissionRepository) async throws -> String {
        let submission = try await repo.submitVersion(versionId: versionId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [submission],
            headers: ["ID", "Platform", "State"],
            rowMapper: { [$0.id, $0.platform.displayName, $0.state.displayName] }
        )
    }
}
