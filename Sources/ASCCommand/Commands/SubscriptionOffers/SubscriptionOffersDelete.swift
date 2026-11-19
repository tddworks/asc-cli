import ArgumentParser
import ASCKit

struct SubscriptionOffersDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete an introductory offer"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Introductory offer ID")
    var offerId: String

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionIntroductoryOffers()
        try await execute(repo: repo)
    }

    func execute(repo: any SubscriptionIntroductoryOffers) async throws {
        try await repo.deleteIntroductoryOffer(offerId: offerId)
    }
}
