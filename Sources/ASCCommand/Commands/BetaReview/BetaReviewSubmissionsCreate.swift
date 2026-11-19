import ArgumentParser
import ASCKit

struct BetaReviewSubmissionsCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Submit a build for beta app review"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Build ID to submit for beta review")
    var buildId: String

    func run() async throws {
        let repo = try ClientProvider.makeBetaAppReviewRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any BetaAppReviewRepository) async throws -> String {
        let submission = try await repo.createSubmission(buildId: buildId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [submission],
            headers: ["ID", "Build ID", "State"],
            rowMapper: { [$0.id, $0.buildId, $0.state.rawValue] }
        )
    }
}
