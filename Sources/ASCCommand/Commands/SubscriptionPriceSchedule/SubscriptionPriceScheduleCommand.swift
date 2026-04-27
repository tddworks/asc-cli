import ArgumentParser

struct SubscriptionPriceScheduleCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "subscription-price-schedule",
        abstract: "Manage the per-territory price schedule for a subscription",
        subcommands: [SubscriptionPriceScheduleGet.self]
    )
}
