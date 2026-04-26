import ArgumentParser

struct IAPOfferCodesPricesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "prices",
        abstract: "Manage IAP offer code per-territory prices",
        subcommands: [IAPOfferCodesPricesList.self]
    )
}
