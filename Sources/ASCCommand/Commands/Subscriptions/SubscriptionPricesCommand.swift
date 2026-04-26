import ArgumentParser

struct SubscriptionPricesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "prices",
        abstract: "Manage subscription per-territory prices",
        subcommands: [SubscriptionPricesSet.self]
    )
}
