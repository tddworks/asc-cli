import ArgumentParser

struct WinBackOffersCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "win-back-offers",
        abstract: "Manage win-back offers for lapsed subscribers",
        subcommands: [
            WinBackOffersList.self,
            WinBackOffersCreate.self,
            WinBackOffersUpdate.self,
            WinBackOffersDelete.self,
            WinBackOffersPricesCommand.self,
        ]
    )
}
