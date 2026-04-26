import ArgumentParser

struct SubscriptionLocalizationsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "subscription-localizations",
        abstract: "Manage subscription localizations",
        subcommands: [
            SubscriptionLocalizationsList.self,
            SubscriptionLocalizationsCreate.self,
            SubscriptionLocalizationsUpdate.self,
            SubscriptionLocalizationsDelete.self,
        ]
    )
}
