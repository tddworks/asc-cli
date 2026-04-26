import ArgumentParser

struct SubscriptionPromotionalOffersCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "subscription-promotional-offers",
        abstract: "Manage subscription promotional offers (with per-territory pricing)",
        subcommands: [
            SubscriptionPromotionalOffersList.self,
            SubscriptionPromotionalOffersCreate.self,
            SubscriptionPromotionalOffersDelete.self,
            SubscriptionPromotionalOffersPricesCommand.self,
        ]
    )
}
