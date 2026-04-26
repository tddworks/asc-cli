import ArgumentParser

struct IAPCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "iap",
        abstract: "Manage in-app purchases",
        subcommands: [
            IAPList.self,
            IAPCreate.self,
            IAPUpdate.self,
            IAPDelete.self,
            IAPSubmit.self,
            IAPUnsubmit.self,
            IAPPricePointsCommand.self,
            IAPPricesCommand.self,
        ]
    )
}
