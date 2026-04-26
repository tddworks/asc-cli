import ArgumentParser

struct SubscriptionOffersCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "subscription-offers",
        abstract: "Manage subscription introductory offers",
        subcommands: [
            SubscriptionOffersList.self,
            SubscriptionOffersCreate.self,
            SubscriptionOffersDelete.self,
        ]
    )
}
