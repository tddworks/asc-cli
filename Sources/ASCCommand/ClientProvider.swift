import ASCKit
import Foundation

struct ClientProvider {
    static func makeApps() throws -> any Apps {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeApps(authProvider: authProvider)
    }

    static func makeAppStoreVersions() throws -> any AppStoreVersions {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeAppStoreVersions(authProvider: authProvider)
    }

    static func makeBuilds() throws -> any Builds {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeBuilds(authProvider: authProvider)
    }

    static func makeTestFlight() throws -> any TestFlight {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeTestFlight(authProvider: authProvider)
    }

    static func makeVersionLocalizations() throws -> any VersionLocalizations {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeVersionLocalizations(authProvider: authProvider)
    }

    static func makeAppScreenshots() throws -> any AppScreenshots {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeAppScreenshots(authProvider: authProvider)
    }

    static func makeAppInfos() throws -> any AppInfos {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeAppInfos(authProvider: authProvider)
    }

    static func makeAppCategories() throws -> any AppCategories {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeAppCategories(authProvider: authProvider)
    }

    static func makeReviewSubmissions() throws -> any ReviewSubmissions {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeReviewSubmissions(authProvider: authProvider)
    }

    static func makeBundleIDs() throws -> any BundleIDs {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeBundleIDs(authProvider: authProvider)
    }

    static func makeCertificates() throws -> any Certificates {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeCertificates(authProvider: authProvider)
    }

    static func makeDevices() throws -> any Devices {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeDevices(authProvider: authProvider)
    }

    static func makeProfiles() throws -> any Profiles {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeProfiles(authProvider: authProvider)
    }

    static func makeBuildUploads() throws -> any BuildUploads {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeBuildUploads(authProvider: authProvider)
    }

    static func makeBetaBuildLocalizations() throws -> any BetaBuildLocalizations {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeBetaBuildLocalizations(authProvider: authProvider)
    }

    static func makeReviewDetails() throws -> any ReviewDetails {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeReviewDetails(authProvider: authProvider)
    }

    static func makeAppPrices() throws -> any AppPrices {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeAppPrices(authProvider: authProvider)
    }

    static func makeAppPreviews() throws -> any AppPreviews {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeAppPreviews(authProvider: authProvider)
    }

    static func makeInAppPurchases() throws -> any InAppPurchases {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeInAppPurchases(authProvider: authProvider)
    }

    static func makeInAppPurchaseLocalizations() throws -> any InAppPurchaseLocalizations {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeInAppPurchaseLocalizations(authProvider: authProvider)
    }

    static func makeSubscriptionGroups() throws -> any SubscriptionGroups {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeSubscriptionGroups(authProvider: authProvider)
    }

    static func makeSubscriptions() throws -> any Subscriptions {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeSubscriptions(authProvider: authProvider)
    }

    static func makeSubscriptionLocalizations() throws -> any SubscriptionLocalizations {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeSubscriptionLocalizations(authProvider: authProvider)
    }

    static func makeSubscriptionGroupLocalizations() throws -> any SubscriptionGroupLocalizations {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeSubscriptionGroupLocalizations(authProvider: authProvider)
    }

    static func makeInAppPurchaseSubmissions() throws -> any InAppPurchaseSubmissions {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeInAppPurchaseSubmissions(authProvider: authProvider)
    }

    static func makeProductVersions() throws -> any ProductVersions {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeProductVersions(authProvider: authProvider)
    }

    static func makeInAppPurchasePrices() throws -> any InAppPurchasePrices {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeInAppPurchasePrices(authProvider: authProvider)
    }

    static func makeSubscriptionPrices() throws -> any SubscriptionPrices {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeSubscriptionPrices(authProvider: authProvider)
    }

    static func makeSubscriptionSubmissions() throws -> any SubscriptionSubmissions {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeSubscriptionSubmissions(authProvider: authProvider)
    }

    static func makeSubscriptionPromotionalOffers() throws -> any SubscriptionPromotionalOffers {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeSubscriptionPromotionalOffers(authProvider: authProvider)
    }

    static func makeWinBackOffers() throws -> any WinBackOffers {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeWinBackOffers(authProvider: authProvider)
    }

    static func makeAssetLibraries() throws -> any AssetLibraries {
        try ClientFactory().makeAssetLibraries(authProvider: CompositeAuthProvider())
    }

    static func makeLibraryImages() throws -> any LibraryImages {
        try ClientFactory().makeLibraryImages(authProvider: CompositeAuthProvider())
    }

    static func makeLibraryVideos() throws -> any LibraryVideos {
        try ClientFactory().makeLibraryVideos(authProvider: CompositeAuthProvider())
    }

    static func makeAssetPlacements() throws -> any AssetPlacements {
        try ClientFactory().makeAssetPlacements(authProvider: CompositeAuthProvider())
    }

    static func makeExperiments() throws -> any Experiments {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeExperiments(authProvider: authProvider)
    }

    static func makePromotedPurchases() throws -> any PromotedPurchases {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makePromotedPurchases(authProvider: authProvider)
    }

    static func makeInAppPurchaseReviewAssets() throws -> any InAppPurchaseReviewAssets {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeInAppPurchaseReviewAssets(authProvider: authProvider)
    }

    static func makeSubscriptionReviewAssets() throws -> any SubscriptionReviewAssets {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeSubscriptionReviewAssets(authProvider: authProvider)
    }

    static func makeSubscriptionIntroductoryOffers() throws -> any SubscriptionIntroductoryOffers {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeSubscriptionIntroductoryOffers(authProvider: authProvider)
    }

    static func makeSubscriptionOfferCodes() throws -> any SubscriptionOfferCodes {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeSubscriptionOfferCodes(authProvider: authProvider)
    }

    static func makeInAppPurchaseOfferCodes() throws -> any InAppPurchaseOfferCodes {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeInAppPurchaseOfferCodes(authProvider: authProvider)
    }

    static func makeAgeRatingDeclarations() throws -> any AgeRatingDeclarations {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeAgeRatingDeclarations(authProvider: authProvider)
    }

    static func makeBetaAppReviews() throws -> any BetaAppReviews {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeBetaAppReviews(authProvider: authProvider)
    }

    static func makeBetaAppLocalizations() throws -> any BetaAppLocalizations {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeBetaAppLocalizations(authProvider: authProvider)
    }

    static func makeAppAvailabilities() throws -> any AppAvailabilities {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeAppAvailabilities(authProvider: authProvider)
    }

    static func makeInAppPurchaseAvailabilities() throws -> any InAppPurchaseAvailabilities {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeInAppPurchaseAvailabilities(authProvider: authProvider)
    }

    static func makeSubscriptionAvailabilities() throws -> any SubscriptionAvailabilities {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeSubscriptionAvailabilities(authProvider: authProvider)
    }

    static func makeTerritories() throws -> any Territories {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeTerritories(authProvider: authProvider)
    }

    // MARK: - Simulators

    static func makeSimulators() -> any Simulators {
        ClientFactory().makeSimulators()
    }

    // SimulatorInteractionRepository moved to ASCPro (pro feature)

    // MARK: - Skills

    static func makeSkills() -> any Skills {
        ClientFactory().makeSkills()
    }

    static func makeSkillConfigStorage() -> any SkillConfigStorage {
        ClientFactory().makeSkillConfigStorage()
    }

    // MARK: - Plugins

    static func makePlugins() -> any Plugins {
        ClientFactory().makePlugins()
    }

    static func makeTemplates() -> AggregateTemplates {
        AggregateTemplates.shared
    }

    static func makeGalleryTemplates() -> AggregateGalleryTemplates {
        AggregateGalleryTemplates.shared
    }

    static func makeThemes() -> AggregateThemes {
        AggregateThemes.shared
    }

    static func makeAuthStorage() -> any AuthStorage {
        FileAuthStorage()
    }

    static func makeEnvironmentAuthProvider() -> any AuthProvider {
        EnvironmentAuthProvider()
    }

    static func makeXcodeBuildRunner() -> any XcodeBuildRunner {
        ProcessXcodeBuildRunner()
    }

    static func makeProjectConfigStorage() -> any ProjectConfigStorage {
        FileProjectConfigStorage()
    }

    static func makeHTMLRenderer() -> any HTMLRenderer {
        WebKitHTMLRenderer()
    }

    static func makeAppShotsConfigStorage() -> any AppShotsConfigStorage {
        FileAppShotsConfigStorage()
    }

    static func makeAppWall(token: String) -> any AppWall {
        GitHubAppWall(token: token)
    }

    static func makeUsers() throws -> any Users {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeUsers(authProvider: authProvider)
    }

    static func makeXcodeCloudProducts() throws -> any XcodeCloudProducts {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeXcodeCloudProducts(authProvider: authProvider)
    }

    static func makeXcodeCloudWorkflows() throws -> any XcodeCloudWorkflows {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeXcodeCloudWorkflows(authProvider: authProvider)
    }

    static func makeXcodeCloudBuildRuns() throws -> any XcodeCloudBuildRuns {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeXcodeCloudBuildRuns(authProvider: authProvider)
    }

    static func makeGameCenter() throws -> any GameCenter {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeGameCenter(authProvider: authProvider)
    }

    static func makeGameCenterModeration() throws -> any GameCenterModeration {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeGameCenterModeration(authProvider: authProvider)
    }

    static func makeAppClips() throws -> any AppClips {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeAppClips(authProvider: authProvider)
    }

    static func makeReports() throws -> any Reports {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeReports(authProvider: authProvider)
    }

    static func makeAnalyticsReports() throws -> any AnalyticsReports {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeAnalyticsReports(authProvider: authProvider)
    }

    static func makeCustomerReviews() throws -> any CustomerReviews {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeCustomerReviews(authProvider: authProvider)
    }

    static func makePerfMetrics() throws -> any PerfMetrics {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makePerfMetrics(authProvider: authProvider)
    }

    static func makePerfOverviews() throws -> any PerfOverviews {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makePerfOverviews(authProvider: authProvider)
    }

    static func makeDiagnostics() throws -> any Diagnostics {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeDiagnostics(authProvider: authProvider)
    }

    // MARK: - Iris (private API, cookie-based auth)

    static func makeIrisAppBundles() -> any IrisAppBundles {
        ClientFactory().makeIrisAppBundles()
    }

    static func makeIrisInAppPurchaseSubmissions() -> any IrisInAppPurchaseSubmissions {
        ClientFactory().makeIrisInAppPurchaseSubmissions()
    }

    static func makeIrisResolutionCenter() -> any IrisResolutionCenter {
        ClientFactory().makeIrisResolutionCenter()
    }

    static func makeIrisCookieProvider() -> any IrisCookieProvider {
        ClientFactory().makeIrisCookieProvider()
    }

    static func makeIrisSignIn() -> any IrisSignIn {
        IrisSDKSignIn()
    }

    static func makeIrisSessions() -> any IrisSessions {
        FileIrisSessions()
    }

    /// File path for the half-finished login state between `login` and `verify-code`.
    /// Stored separately from the persisted session so a rejected 2FA code doesn't blow
    /// away an existing valid session.
    static func pendingTwoFactorURL() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".asc")
            .appendingPathComponent("iris")
            .appendingPathComponent("pending-2fa.json")
    }
}
