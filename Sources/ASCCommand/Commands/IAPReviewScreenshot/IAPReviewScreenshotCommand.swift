import ArgumentParser

struct IAPReviewScreenshotCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "iap-review-screenshot",
        abstract: "Manage the App Store review screenshot for an in-app purchase",
        subcommands: [
            IAPReviewScreenshotGet.self,
            IAPReviewScreenshotUpload.self,
            IAPReviewScreenshotDelete.self,
        ]
    )
}
