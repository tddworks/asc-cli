import AppStoreConnect_Swift_SDK
import Domain
import Foundation

public struct ClientFactory: Sendable {

    public init() {}

    public func makeAppRepository(authProvider: any AuthProvider) throws -> any AppRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKAppRepository(client: provider)
    }

    public func makeVersionRepository(authProvider: any AuthProvider) throws -> any VersionRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKVersionRepository(client: provider)
    }

    public func makeBuildRepository(authProvider: any AuthProvider) throws -> any BuildRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKBuildRepository(client: provider)
    }

    public func makeTestFlightRepository(authProvider: any AuthProvider) throws -> any TestFlightRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKTestFlightRepository(client: provider)
    }

    public func makeVersionLocalizationRepository(authProvider: any AuthProvider) throws -> any VersionLocalizationRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKLocalizationRepository(client: provider)
    }

    public func makeScreenshotRepository(authProvider: any AuthProvider) throws -> any ScreenshotRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKScreenshotRepository(client: provider)
    }

    public func makeAppInfoRepository(authProvider: any AuthProvider) throws -> any AppInfoRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKAppInfoRepository(client: provider)
    }

    public func makeAppCategoryRepository(authProvider: any AuthProvider) throws -> any AppCategoryRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKAppCategoryRepository(client: provider)
    }

    public func makeSubmissionRepository(authProvider: any AuthProvider) throws -> any SubmissionRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return OpenAPISubmissionRepository(client: provider)
    }

    public func makeBundleIDRepository(authProvider: any AuthProvider) throws -> any BundleIDRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKBundleIDRepository(client: provider)
    }

    public func makeCertificateRepository(authProvider: any AuthProvider) throws -> any CertificateRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKCertificateRepository(client: provider)
    }

    public func makeDeviceRepository(authProvider: any AuthProvider) throws -> any DeviceRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKDeviceRepository(client: provider)
    }

    public func makeProfileRepository(authProvider: any AuthProvider) throws -> any ProfileRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKProfileRepository(client: provider)
    }

    public func makeBuildUploadRepository(authProvider: any AuthProvider) throws -> any BuildUploadRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKBuildUploadRepository(client: provider)
    }

    public func makeBetaBuildLocalizationRepository(authProvider: any AuthProvider) throws -> any BetaBuildLocalizationRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKBetaBuildLocalizationRepository(client: provider)
    }

    public func makeReviewDetailRepository(authProvider: any AuthProvider) throws -> any ReviewDetailRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKReviewDetailRepository(client: provider)
    }

    public func makePricingRepository(authProvider: any AuthProvider) throws -> any PricingRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKPricingRepository(client: provider)
    }

    public func makePreviewRepository(authProvider: any AuthProvider) throws -> any PreviewRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return OpenAPIPreviewRepository(client: provider)
    }

    public func makeInAppPurchaseRepository(authProvider: any AuthProvider) throws -> any InAppPurchaseRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKInAppPurchaseRepository(client: provider)
    }

    public func makeInAppPurchaseLocalizationRepository(authProvider: any AuthProvider) throws -> any InAppPurchaseLocalizationRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKInAppPurchaseLocalizationRepository(client: provider)
    }

    public func makeSubscriptionGroupRepository(authProvider: any AuthProvider) throws -> any SubscriptionGroupRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKSubscriptionGroupRepository(client: provider)
    }

    public func makeSubscriptionRepository(authProvider: any AuthProvider) throws -> any SubscriptionRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKSubscriptionRepository(client: provider)
    }

    public func makeSubscriptionLocalizationRepository(authProvider: any AuthProvider) throws -> any SubscriptionLocalizationRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKSubscriptionLocalizationRepository(client: provider)
    }

    public func makeInAppPurchaseSubmissionRepository(authProvider: any AuthProvider) throws -> any InAppPurchaseSubmissionRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKInAppPurchaseSubmissionRepository(client: provider)
    }

    public func makeInAppPurchasePriceRepository(authProvider: any AuthProvider) throws -> any InAppPurchasePriceRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKInAppPurchasePriceRepository(client: provider)
    }

    public func makeSubscriptionSubmissionRepository(authProvider: any AuthProvider) throws -> any SubscriptionSubmissionRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKSubscriptionSubmissionRepository(client: provider)
    }

    public func makeSubscriptionIntroductoryOfferRepository(authProvider: any AuthProvider) throws -> any SubscriptionIntroductoryOfferRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKSubscriptionIntroductoryOfferRepository(client: provider)
    }

    public func makeAgeRatingDeclarationRepository(authProvider: any AuthProvider) throws -> any AgeRatingDeclarationRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKAgeRatingDeclarationRepository(client: provider)
    }

    public func makeUserRepository(authProvider: any AuthProvider) throws -> any UserRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKUserRepository(client: provider)
    }

    // MARK: - Plugins (no ASC auth needed — local filesystem + subprocess)

    public func makePluginRepository() -> any PluginRepository {
        LocalPluginRepository()
    }

    public func makePluginRunner() -> any PluginRunner {
        ProcessPluginRunner()
    }

    public func makePluginEventBus() -> any PluginEventBus {
        let repo = makePluginRepository()
        let runner = makePluginRunner()
        return LocalPluginEventBus(pluginRepository: repo, pluginRunner: runner)
    }

    private func makeProvider(authProvider: any AuthProvider) throws -> APIProvider {
        let credentials = try authProvider.resolve()
        let strippedKey = credentials.privateKeyPEM
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----BEGIN EC PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END EC PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .trimmingCharacters(in: .whitespaces)
        let configuration = try APIConfiguration(
            issuerID: credentials.issuerID,
            privateKeyID: credentials.keyID,
            privateKey: strippedKey
        )
        return APIProvider(configuration: configuration)
    }
}
