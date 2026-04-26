import ArgumentParser

struct SubscriptionOfferCodeOneTimeCodesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "subscription-offer-code-one-time-codes",
        abstract: "Manage subscription offer code one-time use codes",
        subcommands: [
            SubscriptionOfferCodeOneTimeCodesList.self,
            SubscriptionOfferCodeOneTimeCodesCreate.self,
            SubscriptionOfferCodeOneTimeCodesUpdate.self,
            SubscriptionOfferCodeOneTimeCodesValues.self,
        ]
    )
}
