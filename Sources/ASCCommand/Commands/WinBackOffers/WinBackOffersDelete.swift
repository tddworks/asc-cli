import ArgumentParser
import Domain

struct WinBackOffersDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a win-back offer"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Win-back offer ID")
    var offerId: String

    func run() async throws {
        let repo = try ClientProvider.makeWinBackOfferRepository()
        try await execute(repo: repo)
    }

    func execute(repo: any WinBackOfferRepository) async throws {
        try await repo.deleteWinBackOffer(offerId: offerId)
    }
}
