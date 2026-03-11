import ArgumentParser
import Domain

struct ReviewResponsesGet: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get the response to a customer review"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Review ID")
    var reviewId: String

    func run() async throws {
        let repo = try ClientProvider.makeCustomerReviewRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any CustomerReviewRepository) async throws -> String {
        let response = try await repo.getResponse(reviewId: reviewId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [response],
            headers: ["ID", "Review ID", "Response Body", "State"],
            rowMapper: { [$0.id, $0.reviewId, $0.responseBody, $0.state.rawValue] }
        )
    }
}
