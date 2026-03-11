import ArgumentParser
import Domain

struct ReviewsGet: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get a customer review"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Review ID")
    var reviewId: String

    func run() async throws {
        let repo = try ClientProvider.makeCustomerReviewRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any CustomerReviewRepository) async throws -> String {
        let review = try await repo.getReview(reviewId: reviewId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [review],
            headers: ["ID", "Rating", "Title", "Body", "Reviewer", "Territory"],
            rowMapper: { [$0.id, "\($0.rating)", $0.title ?? "", $0.body ?? "", $0.reviewerNickname ?? "", $0.territory ?? ""] }
        )
    }
}
