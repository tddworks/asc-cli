import ArgumentParser

struct SubscriptionOfferCodesPricesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "prices",
        abstract: "Manage subscription offer code per-territory prices",
        subcommands: [SubscriptionOfferCodesPricesList.self]
    )
}
