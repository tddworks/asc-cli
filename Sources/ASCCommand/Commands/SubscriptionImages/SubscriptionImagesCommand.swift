import ArgumentParser

struct SubscriptionImagesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "subscription-images",
        abstract: "Manage promotional images for a subscription",
        subcommands: [
            SubscriptionImagesList.self,
            SubscriptionImagesUpload.self,
            SubscriptionImagesDelete.self,
        ]
    )
}
