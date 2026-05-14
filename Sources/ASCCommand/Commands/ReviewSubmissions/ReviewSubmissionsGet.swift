import ArgumentParser
import Domain

struct ReviewSubmissionsGet: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get a single App Store review submission by id (state + affordances to drill into items)"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Submission ID to fetch")
    var submissionId: String

    func run() async throws {
        let repo = try ClientProvider.makeSubmissionRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any SubmissionRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let submission = try await repo.getSubmission(id: submissionId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([submission], affordanceMode: affordanceMode)
    }
}
