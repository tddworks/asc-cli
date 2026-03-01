import ArgumentParser

@main
struct ASC: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "asc",
        abstract: "App Store Connect CLI",
        version: ascVersion,
        subcommands: [
            AppsCommand.self,
            VersionsCommand.self,
            VersionLocalizationsCommand.self,
            ScreenshotSetsCommand.self,
            ScreenshotsCommand.self,
            AppInfosCommand.self,
            AppInfoLocalizationsCommand.self,
            BuildsCommand.self,
            TestFlightCommand.self,
            AuthCommand.self,
            VersionCommand.self,
            TUICommand.self,
            BundleIDsCommand.self,
            CertificatesCommand.self,
            DevicesCommand.self,
            ProfilesCommand.self,
            AppPreviewSetsCommand.self,
            AppPreviewsCommand.self,
            IAPCommand.self,
            IAPLocalizationsCommand.self,
            SubscriptionGroupsCommand.self,
            SubscriptionsCommand.self,
            SubscriptionLocalizationsCommand.self,
            SubscriptionOffersCommand.self,
            AppShotsCommand.self,
            AgeRatingCommand.self,
            AppCategoriesCommand.self,
            VersionReviewDetailCommand.self,
        ]
    )
}
