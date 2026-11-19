import ArgumentParser
import ASCKit

struct ReviewSubmissionsSubmit: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "submit",
        abstract: "Send a draft review submission, with all its items, to App Review"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Review submission ID")
    var submissionId: String

    func run() async throws {
        let repo = try ClientProvider.makeSubmissionRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any SubmissionRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let submission = try await repo.submit(submissionId: submissionId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([submission], affordanceMode: affordanceMode)
    }
}
