import ArgumentParser
import Domain

struct ReviewResponsesDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a response to a customer review"
    )

    @Option(name: .long, help: "Response ID")
    var responseId: String

    func run() async throws {
        let repo = try ClientProvider.makeCustomerReviewRepository()
        try await execute(repo: repo)
    }

    func execute(repo: any CustomerReviewRepository) async throws {
        try await repo.deleteResponse(responseId: responseId)
    }
}
