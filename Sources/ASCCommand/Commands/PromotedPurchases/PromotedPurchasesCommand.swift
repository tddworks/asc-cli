import ArgumentParser

struct PromotedPurchasesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "promoted-purchases",
        abstract: "Manage promoted in-app purchases (App Store product page slots)",
        subcommands: [
            PromotedPurchasesList.self,
            PromotedPurchasesCreate.self,
            PromotedPurchasesUpdate.self,
            PromotedPurchasesDelete.self,
        ]
    )
}
