import ArgumentParser

struct SubscriptionGroupLocalizationsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "subscription-group-localizations",
        abstract: "Manage subscription group localizations (display name and custom app name per locale)",
        subcommands: [
            SubscriptionGroupLocalizationsList.self,
            SubscriptionGroupLocalizationsCreate.self,
            SubscriptionGroupLocalizationsUpdate.self,
            SubscriptionGroupLocalizationsDelete.self,
        ]
    )
}
