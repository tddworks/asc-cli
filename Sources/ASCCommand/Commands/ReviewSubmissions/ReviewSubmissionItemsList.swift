import ArgumentParser
import Domain

struct ReviewSubmissionItemsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List items in a review submission; filter by state to surface rejected items"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Submission ID whose items to list")
    var submissionId: String

    @Option(name: .long, help: "Filter by item state (e.g. REJECTED, APPROVED, READY_FOR_REVIEW)")
    var state: String?

    func run() async throws {
        let repo = try ClientProvider.makeSubmissionRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any SubmissionRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        var items = try await repo.listSubmissionItems(submissionId: submissionId)
        if let filter = state.flatMap({ ReviewSubmissionItemState(rawValue: $0.uppercased()) }) {
            items = items.filter { $0.state == filter }
        }
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(items, affordanceMode: affordanceMode)
    }
}
