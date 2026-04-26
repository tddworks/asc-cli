import ArgumentParser

struct SubscriptionPromotionalOffersPricesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "prices",
        abstract: "Manage promotional offer per-territory prices",
        subcommands: [SubscriptionPromotionalOffersPricesList.self]
    )
}
