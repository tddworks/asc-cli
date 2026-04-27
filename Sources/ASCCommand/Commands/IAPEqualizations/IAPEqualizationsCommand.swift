import ArgumentParser

struct IAPEqualizationsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "iap-equalizations",
        abstract: "List Apple's auto-equalized territory prices for a given IAP price point",
        subcommands: [IAPEqualizationsList.self]
    )
}
