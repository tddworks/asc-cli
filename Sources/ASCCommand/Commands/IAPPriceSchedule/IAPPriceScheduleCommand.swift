import ArgumentParser

struct IAPPriceScheduleCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "iap-price-schedule",
        abstract: "Manage the price schedule (currently set price) for an in-app purchase",
        subcommands: [IAPPriceScheduleGet.self]
    )
}
