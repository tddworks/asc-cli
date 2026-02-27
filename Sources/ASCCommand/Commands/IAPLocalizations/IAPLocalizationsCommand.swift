import ArgumentParser

struct IAPLocalizationsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "iap-localizations",
        abstract: "Manage in-app purchase localizations",
        subcommands: [
            IAPLocalizationsList.self,
            IAPLocalizationsCreate.self,
        ]
    )
}
