import ArgumentParser
import Domain

struct SubscriptionPromotionalOffersDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a promotional offer"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Promotional offer ID")
    var offerId: String

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionPromotionalOfferRepository()
        try await execute(repo: repo)
    }

    func execute(repo: any SubscriptionPromotionalOfferRepository) async throws {
        try await repo.deletePromotionalOffer(offerId: offerId)
    }
}
