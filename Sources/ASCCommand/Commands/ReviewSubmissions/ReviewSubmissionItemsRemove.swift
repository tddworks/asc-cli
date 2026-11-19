import ArgumentParser
import ASCKit

struct ReviewSubmissionItemsRemove: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "remove",
        abstract: "Remove an item from a draft review submission"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Review submission item ID")
    var itemId: String

    func run() async throws {
        let repo = try ClientProvider.makeReviewSubmissions()
        try await execute(repo: repo)
    }

    func execute(repo: any ReviewSubmissions) async throws {
        try await repo.removeItem(itemId: itemId)
    }
}
