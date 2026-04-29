import Domain
import Foundation
import Infrastructure

struct ClientProvider {
    static func makeAppRepository() throws -> any AppRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeAppRepository(authProvider: authProvider)
    }

    static func makeVersionRepository() throws -> any VersionRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeVersionRepository(authProvider: authProvider)
    }

    static func makeBuildRepository() throws -> any BuildRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeBuildRepository(authProvider: authProvider)
    }

    static func makeTestFlightRepository() throws -> any TestFlightRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeTestFlightRepository(authProvider: authProvider)
    }

    static func makeVersionLocalizationRepository() throws -> any VersionLocalizationRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeVersionLocalizationRepository(authProvider: authProvider)
    }

    static func makeScreenshotRepository() throws -> any ScreenshotRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeScreenshotRepository(authProvider: authProvider)
    }

    static func makeAppInfoRepository() throws -> any AppInfoRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeAppInfoRepository(authProvider: authProvider)
    }

    static func makeAppCategoryRepository() throws -> any AppCategoryRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeAppCategoryRepository(authProvider: authProvider)
    }

    static func makeSubmissionRepository() throws -> any SubmissionRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeSubmissionRepository(authProvider: authProvider)
    }

    static func makeBundleIDRepository() throws -> any BundleIDRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeBundleIDRepository(authProvider: authProvider)
    }

    static func makeCertificateRepository() throws -> any CertificateRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeCertificateRepository(authProvider: authProvider)
    }

    static func makeDeviceRepository() throws -> any DeviceRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeDeviceRepository(authProvider: authProvider)
    }

    static func makeProfileRepository() throws -> any ProfileRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeProfileRepository(authProvider: authProvider)
    }

    static func makeBuildUploadRepository() throws -> any BuildUploadRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeBuildUploadRepository(authProvider: authProvider)
    }

    static func makeBetaBuildLocalizationRepository() throws -> any BetaBuildLocalizationRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeBetaBuildLocalizationRepository(authProvider: authProvider)
    }

    static func makeReviewDetailRepository() throws -> any ReviewDetailRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeReviewDetailRepository(authProvider: authProvider)
    }

    static func makePricingRepository() throws -> any PricingRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makePricingRepository(authProvider: authProvider)
    }

    static func makePreviewRepository() throws -> any PreviewRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makePreviewRepository(authProvider: authProvider)
    }

    static func makeInAppPurchaseRepository() throws -> any InAppPurchaseRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeInAppPurchaseRepository(authProvider: authProvider)
    }

    static func makeInAppPurchaseLocalizationRepository() throws -> any InAppPurchaseLocalizationRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeInAppPurchaseLocalizationRepository(authProvider: authProvider)
    }

    static func makeSubscriptionGroupRepository() throws -> any SubscriptionGroupRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeSubscriptionGroupRepository(authProvider: authProvider)
    }

    static func makeSubscriptionRepository() throws -> any SubscriptionRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeSubscriptionRepository(authProvider: authProvider)
    }

    static func makeSubscriptionLocalizationRepository() throws -> any SubscriptionLocalizationRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeSubscriptionLocalizationRepository(authProvider: authProvider)
    }

    static func makeSubscriptionGroupLocalizationRepository() throws -> any SubscriptionGroupLocalizationRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeSubscriptionGroupLocalizationRepository(authProvider: authProvider)
    }

    static func makeInAppPurchaseSubmissionRepository() throws -> any InAppPurchaseSubmissionRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeInAppPurchaseSubmissionRepository(authProvider: authProvider)
    }

    static func makeInAppPurchasePriceRepository() throws -> any InAppPurchasePriceRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeInAppPurchasePriceRepository(authProvider: authProvider)
    }

    static func makeSubscriptionPriceRepository() throws -> any SubscriptionPriceRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeSubscriptionPriceRepository(authProvider: authProvider)
    }

    static func makeSubscriptionSubmissionRepository() throws -> any SubscriptionSubmissionRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeSubscriptionSubmissionRepository(authProvider: authProvider)
    }

    static func makeSubscriptionPromotionalOfferRepository() throws -> any SubscriptionPromotionalOfferRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeSubscriptionPromotionalOfferRepository(authProvider: authProvider)
    }

    static func makeWinBackOfferRepository() throws -> any WinBackOfferRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeWinBackOfferRepository(authProvider: authProvider)
    }

    static func makePromotedPurchaseRepository() throws -> any PromotedPurchaseRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makePromotedPurchaseRepository(authProvider: authProvider)
    }

    static func makeInAppPurchaseReviewRepository() throws -> any InAppPurchaseReviewRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeInAppPurchaseReviewRepository(authProvider: authProvider)
    }

    static func makeSubscriptionReviewRepository() throws -> any SubscriptionReviewRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeSubscriptionReviewRepository(authProvider: authProvider)
    }

    static func makeSubscriptionIntroductoryOfferRepository() throws -> any SubscriptionIntroductoryOfferRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeSubscriptionIntroductoryOfferRepository(authProvider: authProvider)
    }

    static func makeSubscriptionOfferCodeRepository() throws -> any SubscriptionOfferCodeRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeSubscriptionOfferCodeRepository(authProvider: authProvider)
    }

    static func makeInAppPurchaseOfferCodeRepository() throws -> any InAppPurchaseOfferCodeRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeInAppPurchaseOfferCodeRepository(authProvider: authProvider)
    }

    static func makeAgeRatingDeclarationRepository() throws -> any AgeRatingDeclarationRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeAgeRatingDeclarationRepository(authProvider: authProvider)
    }

    static func makeBetaAppReviewRepository() throws -> any BetaAppReviewRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeBetaAppReviewRepository(authProvider: authProvider)
    }

    static func makeAppAvailabilityRepository() throws -> any AppAvailabilityRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeAppAvailabilityRepository(authProvider: authProvider)
    }

    static func makeInAppPurchaseAvailabilityRepository() throws -> any InAppPurchaseAvailabilityRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeInAppPurchaseAvailabilityRepository(authProvider: authProvider)
    }

    static func makeSubscriptionAvailabilityRepository() throws -> any SubscriptionAvailabilityRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeSubscriptionAvailabilityRepository(authProvider: authProvider)
    }

    static func makeTerritoryRepository() throws -> any TerritoryRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeTerritoryRepository(authProvider: authProvider)
    }

    // MARK: - Simulators

    static func makeSimulatorRepository() -> any SimulatorRepository {
        ClientFactory().makeSimulatorRepository()
    }

    // SimulatorInteractionRepository moved to ASCPro (pro feature)

    // MARK: - Skills

    static func makeSkillRepository() -> any SkillRepository {
        ClientFactory().makeSkillRepository()
    }

    static func makeSkillConfigStorage() -> any SkillConfigStorage {
        ClientFactory().makeSkillConfigStorage()
    }

    // MARK: - Plugins

    static func makePluginRepository() -> any PluginRepository {
        ClientFactory().makePluginRepository()
    }

    static func makeTemplateRepository() -> AggregateTemplateRepository {
        AggregateTemplateRepository.shared
    }

    static func makeGalleryTemplateRepository() -> AggregateGalleryTemplateRepository {
        AggregateGalleryTemplateRepository.shared
    }

    static func makeThemeRepository() -> AggregateThemeRepository {
        AggregateThemeRepository.shared
    }

    static func makeHTMLRenderer() -> any HTMLRenderer {
        WebKitHTMLRenderer()
    }

    static func makeAppShotsConfigStorage() -> any AppShotsConfigStorage {
        FileAppShotsConfigStorage()
    }

    static func makeAppWallRepository(token: String) -> any AppWallRepository {
        GitHubAppWallRepository(token: token)
    }

    static func makeUserRepository() throws -> any UserRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeUserRepository(authProvider: authProvider)
    }

    static func makeXcodeCloudProductRepository() throws -> any XcodeCloudProductRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeXcodeCloudProductRepository(authProvider: authProvider)
    }

    static func makeXcodeCloudWorkflowRepository() throws -> any XcodeCloudWorkflowRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeXcodeCloudWorkflowRepository(authProvider: authProvider)
    }

    static func makeXcodeCloudBuildRunRepository() throws -> any XcodeCloudBuildRunRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeXcodeCloudBuildRunRepository(authProvider: authProvider)
    }

    static func makeGameCenterRepository() throws -> any GameCenterRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeGameCenterRepository(authProvider: authProvider)
    }

    static func makeAppClipRepository() throws -> any AppClipRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeAppClipRepository(authProvider: authProvider)
    }

    static func makeReportRepository() throws -> any ReportRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeReportRepository(authProvider: authProvider)
    }

    static func makeAnalyticsReportRepository() throws -> any AnalyticsReportRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeAnalyticsReportRepository(authProvider: authProvider)
    }

    static func makeCustomerReviewRepository() throws -> any CustomerReviewRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeCustomerReviewRepository(authProvider: authProvider)
    }

    static func makePerfMetricsRepository() throws -> any PerfMetricsRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makePerfMetricsRepository(authProvider: authProvider)
    }

    static func makeDiagnosticsRepository() throws -> any DiagnosticsRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeDiagnosticsRepository(authProvider: authProvider)
    }

    // MARK: - Iris (private API, cookie-based auth)

    static func makeIrisAppBundleRepository() -> any IrisAppBundleRepository {
        ClientFactory().makeIrisAppBundleRepository()
    }

    static func makeIrisInAppPurchaseSubmissionRepository() -> any IrisInAppPurchaseSubmissionRepository {
        ClientFactory().makeIrisInAppPurchaseSubmissionRepository()
    }

    static func makeIrisCookieProvider() -> any IrisCookieProvider {
        ClientFactory().makeIrisCookieProvider()
    }

    static func makeIrisAuthRepository() -> any IrisAuthRepository {
        IrisAuthSDKRepository()
    }

    static func makeIrisSessionRepository() -> any IrisSessionRepository {
        FileIrisSessionRepository()
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
