import ArgumentParser

struct SubscriptionsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "subscriptions",
        abstract: "Manage subscriptions",
        subcommands: [
            SubscriptionsList.self,
            SubscriptionsCreate.self,
            SubscriptionsUpdate.self,
            SubscriptionsDelete.self,
            SubscriptionsSubmit.self,
            SubscriptionsUnsubmit.self,
            SubscriptionPricePointsCommand.self,
            SubscriptionPricesCommand.self,
        ]
    )
}
