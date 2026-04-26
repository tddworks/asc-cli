import ArgumentParser

struct SubscriptionOfferCodesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "subscription-offer-codes",
        abstract: "Manage subscription offer codes",
        subcommands: [
            SubscriptionOfferCodesList.self,
            SubscriptionOfferCodesCreate.self,
            SubscriptionOfferCodesUpdate.self,
            SubscriptionOfferCodesPricesCommand.self,
        ]
    )
}
