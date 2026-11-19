import ArgumentParser
import ASCKit

struct ReviewResponsesDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a response to a customer review"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Response ID")
    var responseId: String

    func run() async throws {
        let repo = try ClientProvider.makeCustomerReviews()
        try await execute(repo: repo)
    }

    func execute(repo: any CustomerReviews) async throws {
        try await repo.deleteResponse(responseId: responseId)
    }
}
