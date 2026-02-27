import ArgumentParser

struct SubscriptionsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "subscriptions",
        abstract: "Manage subscriptions",
        subcommands: [
            SubscriptionsList.self,
            SubscriptionsCreate.self,
        ]
    )
}
