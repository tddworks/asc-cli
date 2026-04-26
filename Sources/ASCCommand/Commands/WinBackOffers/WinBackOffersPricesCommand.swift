import ArgumentParser

struct WinBackOffersPricesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "prices",
        abstract: "Manage win-back offer per-territory prices",
        subcommands: [WinBackOffersPricesList.self]
    )
}
