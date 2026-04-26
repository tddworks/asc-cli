import ArgumentParser

struct SubscriptionPricePointsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "price-points",
        abstract: "Manage subscription price points",
        subcommands: [SubscriptionPricePointsList.self]
    )
}
