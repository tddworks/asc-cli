import ArgumentParser
import ASCKit

struct SubscriptionPromotionalOffersDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a promotional offer"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Promotional offer ID")
    var offerId: String

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionPromotionalOffers()
        try await execute(repo: repo)
    }

    func execute(repo: any SubscriptionPromotionalOffers) async throws {
        try await repo.deletePromotionalOffer(offerId: offerId)
    }
}
