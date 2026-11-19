import ArgumentParser
import ASCKit

struct BetaReviewSubmissionsGet: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get a specific beta app review submission"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Beta app review submission ID")
    var submissionId: String

    func run() async throws {
        let repo = try ClientProvider.makeBetaAppReviewRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any BetaAppReviewRepository) async throws -> String {
        let submission = try await repo.getSubmission(id: submissionId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [submission],
            headers: ["ID", "Build ID", "State", "Submitted Date"],
            rowMapper: { [$0.id, $0.buildId, $0.state.rawValue, $0.submittedDate?.description ?? "-"] }
        )
    }
}
