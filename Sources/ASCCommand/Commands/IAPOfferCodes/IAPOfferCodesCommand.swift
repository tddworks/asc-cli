import ArgumentParser

struct IAPOfferCodesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "iap-offer-codes",
        abstract: "Manage in-app purchase offer codes",
        subcommands: [
            IAPOfferCodesList.self,
            IAPOfferCodesCreate.self,
            IAPOfferCodesUpdate.self,
            IAPOfferCodesPricesCommand.self,
        ]
    )
}
