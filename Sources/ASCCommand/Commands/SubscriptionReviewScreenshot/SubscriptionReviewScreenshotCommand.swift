import ArgumentParser

struct SubscriptionReviewScreenshotCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "subscription-review-screenshot",
        abstract: "Manage the App Store review screenshot for a subscription",
        subcommands: [
            SubscriptionReviewScreenshotGet.self,
            SubscriptionReviewScreenshotUpload.self,
            SubscriptionReviewScreenshotDelete.self,
        ]
    )
}
