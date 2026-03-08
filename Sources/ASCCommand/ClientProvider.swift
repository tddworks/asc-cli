import Domain
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

    static func makeSubscriptionSubmissionRepository() throws -> any SubscriptionSubmissionRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeSubscriptionSubmissionRepository(authProvider: authProvider)
    }

    static func makeSubscriptionIntroductoryOfferRepository() throws -> any SubscriptionIntroductoryOfferRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeSubscriptionIntroductoryOfferRepository(authProvider: authProvider)
    }

    static func makeAgeRatingDeclarationRepository() throws -> any AgeRatingDeclarationRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeAgeRatingDeclarationRepository(authProvider: authProvider)
    }

    // MARK: - Plugins

    static func makePluginRepository() -> any PluginRepository {
        ClientFactory().makePluginRepository()
    }

    static func makePluginRunner() -> any PluginRunner {
        ClientFactory().makePluginRunner()
    }

    static func makePluginEventBus() -> any PluginEventBus {
        ClientFactory().makePluginEventBus()
    }

    static func makeScreenshotGenerationRepository(apiKey: String, model: String = "gemini-3.1-flash-image-preview") -> any ScreenshotGenerationRepository {
        GeminiScreenshotGenerationRepository(apiKey: apiKey, model: model)
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
}
