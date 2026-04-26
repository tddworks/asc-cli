import ArgumentParser

struct IAPOfferCodeOneTimeCodesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "iap-offer-code-one-time-codes",
        abstract: "Manage in-app purchase offer code one-time use codes",
        subcommands: [
            IAPOfferCodeOneTimeCodesList.self,
            IAPOfferCodeOneTimeCodesCreate.self,
            IAPOfferCodeOneTimeCodesUpdate.self,
            IAPOfferCodeOneTimeCodesValues.self,
        ]
    )
}
