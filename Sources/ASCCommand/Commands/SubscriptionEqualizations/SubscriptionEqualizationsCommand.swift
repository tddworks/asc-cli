import ArgumentParser

struct SubscriptionEqualizationsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "subscription-equalizations",
        abstract: "List Apple's auto-equalized territory prices for a given subscription price point",
        subcommands: [SubscriptionEqualizationsList.self]
    )
}
