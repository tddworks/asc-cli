import ArgumentParser
import Domain

struct ReviewsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List customer reviews for an app"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID")
    var appId: String

    func run() async throws {
        let repo = try ClientProvider.makeCustomerReviewRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any CustomerReviewRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let reviews = try await repo.listReviews(appId: appId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            reviews,
            headers: ["ID", "Rating", "Title", "Reviewer", "Territory"],
            rowMapper: { [$0.id, "\($0.rating)", $0.title ?? "", $0.reviewerNickname ?? "", $0.territory ?? ""] },
            affordanceMode: affordanceMode
        )
    }
}
