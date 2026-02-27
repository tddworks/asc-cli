import ArgumentParser

struct SubscriptionGroupsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "subscription-groups",
        abstract: "Manage subscription groups",
        subcommands: [
            SubscriptionGroupsList.self,
            SubscriptionGroupsCreate.self,
        ]
    )
}
