import AppStoreConnect_Swift_SDK
import Foundation

public struct ClientFactory: Sendable {

    public init() {}

    public func makeApps(authProvider: any AuthProvider) throws -> any Apps {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKApps(client: provider)
    }

    public func makeAppStoreVersions(authProvider: any AuthProvider) throws -> any AppStoreVersions {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKAppStoreVersions(client: provider)
    }

    public func makeBuilds(authProvider: any AuthProvider) throws -> any Builds {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKBuilds(client: provider)
    }

    public func makeTestFlight(authProvider: any AuthProvider) throws -> any TestFlight {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKTestFlight(client: provider)
    }

    public func makeVersionLocalizations(authProvider: any AuthProvider) throws -> any VersionLocalizations {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKVersionLocalizations(client: provider)
    }

    public func makeAppScreenshots(authProvider: any AuthProvider) throws -> any AppScreenshots {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKAppScreenshots(client: provider)
    }

    public func makeAppInfos(authProvider: any AuthProvider) throws -> any AppInfos {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKAppInfos(client: provider)
    }

    public func makeAppCategories(authProvider: any AuthProvider) throws -> any AppCategories {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKAppCategories(client: provider)
    }

    public func makeReviewSubmissions(authProvider: any AuthProvider) throws -> any ReviewSubmissions {
        let provider = try makeProvider(authProvider: authProvider)
        return OpenAPIReviewSubmissions(client: provider)
    }

    public func makeBundleIDs(authProvider: any AuthProvider) throws -> any BundleIDs {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKBundleIDs(client: provider)
    }

    public func makeCertificates(authProvider: any AuthProvider) throws -> any Certificates {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKCertificates(client: provider)
    }

    public func makeDevices(authProvider: any AuthProvider) throws -> any Devices {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKDevices(client: provider)
    }

    public func makeProfiles(authProvider: any AuthProvider) throws -> any Profiles {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKProfiles(client: provider)
    }

    public func makeBuildUploads(authProvider: any AuthProvider) throws -> any BuildUploads {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKBuildUploads(client: provider)
    }

    public func makeBetaBuildLocalizations(authProvider: any AuthProvider) throws -> any BetaBuildLocalizations {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKBetaBuildLocalizations(client: provider)
    }

    public func makeReviewDetails(authProvider: any AuthProvider) throws -> any ReviewDetails {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKReviewDetails(client: provider)
    }

    public func makeAppPrices(authProvider: any AuthProvider) throws -> any AppPrices {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKAppPrices(client: provider)
    }

    public func makeAppPreviews(authProvider: any AuthProvider) throws -> any AppPreviews {
        let provider = try makeProvider(authProvider: authProvider)
        return OpenAPIAppPreviews(client: provider)
    }

    public func makeInAppPurchases(authProvider: any AuthProvider) throws -> any InAppPurchases {
        let provider = try makeProvider(authProvider: authProvider)
        // Best-effort iris enrichment for `submitWithNextAppStoreVersion`. The closure
        // resolves iris cookies on every list call (so freshly-logged-in sessions are
        // picked up); any failure — no cookies, network error, malformed response —
        // returns an empty map and the SDK list still succeeds with the flag = false.
        let cookieProvider = makeIrisCookieProvider()
        let stateRepo = IrisSDKInAppPurchaseStates()
        let irisFlagsProvider: @Sendable (String) async -> [String: Bool] = { appId in
            guard let session = try? cookieProvider.resolveSession() else { return [:] }
            return (try? await stateRepo.fetchSubmitFlags(session: session, appId: appId)) ?? [:]
        }
        return SDKInAppPurchases(client: provider, irisFlagsProvider: irisFlagsProvider)
    }

    public func makeInAppPurchaseLocalizations(authProvider: any AuthProvider) throws -> any InAppPurchaseLocalizations {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKInAppPurchaseLocalizations(client: provider)
    }

    public func makeSubscriptionGroups(authProvider: any AuthProvider) throws -> any SubscriptionGroups {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKSubscriptionGroups(client: provider)
    }

    public func makeSubscriptions(authProvider: any AuthProvider) throws -> any Subscriptions {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKSubscriptions(client: provider)
    }

    public func makeSubscriptionLocalizations(authProvider: any AuthProvider) throws -> any SubscriptionLocalizations {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKSubscriptionLocalizations(client: provider)
    }

    public func makeSubscriptionGroupLocalizations(authProvider: any AuthProvider) throws -> any SubscriptionGroupLocalizations {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKSubscriptionGroupLocalizations(client: provider)
    }

    public func makeInAppPurchaseSubmissions(authProvider: any AuthProvider) throws -> any InAppPurchaseSubmissions {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKInAppPurchaseSubmissions(client: provider)
    }

    public func makeProductVersions(authProvider: any AuthProvider) throws -> any ProductVersions {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKProductVersions(client: provider)
    }

    public func makeInAppPurchasePrices(authProvider: any AuthProvider) throws -> any InAppPurchasePrices {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKInAppPurchasePrices(client: provider)
    }

    public func makeSubscriptionPrices(authProvider: any AuthProvider) throws -> any SubscriptionPrices {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKSubscriptionPrices(client: provider)
    }

    public func makeSubscriptionSubmissions(authProvider: any AuthProvider) throws -> any SubscriptionSubmissions {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKSubscriptionSubmissions(client: provider)
    }

    public func makeSubscriptionIntroductoryOffers(authProvider: any AuthProvider) throws -> any SubscriptionIntroductoryOffers {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKSubscriptionIntroductoryOffers(client: provider)
    }

    public func makeSubscriptionPromotionalOffers(authProvider: any AuthProvider) throws -> any SubscriptionPromotionalOffers {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKSubscriptionPromotionalOffers(client: provider)
    }

    public func makeWinBackOffers(authProvider: any AuthProvider) throws -> any WinBackOffers {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKWinBackOffers(client: provider)
    }

    public func makeAssetLibraries(authProvider: any AuthProvider) throws -> any AssetLibraries {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKAssetLibraries(client: provider)
    }

    public func makeLibraryImages(authProvider: any AuthProvider) throws -> any LibraryImages {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKLibraryImages(client: provider)
    }

    public func makeLibraryVideos(authProvider: any AuthProvider) throws -> any LibraryVideos {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKLibraryVideos(client: provider)
    }

    public func makeAssetPlacements(authProvider: any AuthProvider) throws -> any AssetPlacements {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKAssetPlacements(client: provider)
    }

    public func makeExperiments(authProvider: any AuthProvider) throws -> any Experiments {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKExperiments(client: provider)
    }

    public func makePromotedPurchases(authProvider: any AuthProvider) throws -> any PromotedPurchases {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKPromotedPurchases(client: provider)
    }

    public func makeInAppPurchaseReviewAssets(authProvider: any AuthProvider) throws -> any InAppPurchaseReviewAssets {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKInAppPurchaseReviewAssets(client: provider)
    }

    public func makeSubscriptionReviewAssets(authProvider: any AuthProvider) throws -> any SubscriptionReviewAssets {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKSubscriptionReviewAssets(client: provider)
    }

    public func makeSubscriptionOfferCodes(authProvider: any AuthProvider) throws -> any SubscriptionOfferCodes {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKSubscriptionOfferCodes(client: provider)
    }

    public func makeInAppPurchaseOfferCodes(authProvider: any AuthProvider) throws -> any InAppPurchaseOfferCodes {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKInAppPurchaseOfferCodes(client: provider)
    }

    public func makeAgeRatingDeclarations(authProvider: any AuthProvider) throws -> any AgeRatingDeclarations {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKAgeRatingDeclarations(client: provider)
    }

    public func makeUsers(authProvider: any AuthProvider) throws -> any Users {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKUsers(client: provider)
    }

    public func makeXcodeCloudProducts(authProvider: any AuthProvider) throws -> any XcodeCloudProducts {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKXcodeCloudProducts(client: provider)
    }

    public func makeXcodeCloudWorkflows(authProvider: any AuthProvider) throws -> any XcodeCloudWorkflows {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKXcodeCloudWorkflows(client: provider)
    }

    public func makeXcodeCloudBuildRuns(authProvider: any AuthProvider) throws -> any XcodeCloudBuildRuns {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKXcodeCloudBuildRuns(client: provider)
    }

    public func makeGameCenter(authProvider: any AuthProvider) throws -> any GameCenter {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKGameCenter(client: provider)
    }

    public func makeGameCenterModeration(authProvider: any AuthProvider) throws -> any GameCenterModeration {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKGameCenterModeration(client: provider)
    }

    public func makeAppClips(authProvider: any AuthProvider) throws -> any AppClips {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKAppClips(client: provider)
    }

    public func makeReports(authProvider: any AuthProvider) throws -> any Reports {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKReports(client: provider)
    }

    public func makeAnalyticsReports(authProvider: any AuthProvider) throws -> any AnalyticsReports {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKAnalyticsReports(client: provider)
    }

    public func makeCustomerReviews(authProvider: any AuthProvider) throws -> any CustomerReviews {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKCustomerReviews(client: provider)
    }

    public func makePerfMetrics(authProvider: any AuthProvider) throws -> any PerfMetrics {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKPerfMetrics(client: provider)
    }

    public func makePerfOverviews(authProvider: any AuthProvider) throws -> any PerfOverviews {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKPerfOverviews(client: provider)
    }

    public func makeDiagnostics(authProvider: any AuthProvider) throws -> any Diagnostics {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKDiagnostics(client: provider)
    }

    public func makeBetaAppReviews(authProvider: any AuthProvider) throws -> any BetaAppReviews {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKBetaAppReviews(client: provider)
    }

    public func makeBetaAppLocalizations(authProvider: any AuthProvider) throws -> any BetaAppLocalizations {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKBetaAppLocalizations(client: provider)
    }

    public func makeInAppPurchaseAvailabilities(authProvider: any AuthProvider) throws -> any InAppPurchaseAvailabilities {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKInAppPurchaseAvailabilities(client: provider)
    }

    public func makeSubscriptionAvailabilities(authProvider: any AuthProvider) throws -> any SubscriptionAvailabilities {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKSubscriptionAvailabilities(client: provider)
    }

    public func makeAppAvailabilities(authProvider: any AuthProvider) throws -> any AppAvailabilities {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKAppAvailabilities(client: provider)
    }

    public func makeTerritories(authProvider: any AuthProvider) throws -> any Territories {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKTerritories(client: provider)
    }

    // MARK: - Simulators (no ASC auth needed — local xcrun simctl)

    public func makeSimulators() -> any Simulators {
        SimctlSimulators()
    }

    // SimulatorInteractionRepository moved to ASCPro (pro feature)

    // MARK: - Skills (no ASC auth needed — subprocess + local filesystem)

    public func makeSkills() -> any Skills {
        ProcessSkills()
    }

    public func makeSkillConfigStorage() -> any SkillConfigStorage {
        FileSkillConfigStorage()
    }

    // MARK: - Plugins (no ASC auth needed — local filesystem + GitHub registry)

    public func makePlugins() -> any Plugins {
        MarketplacePlugins(sources: [
            GitHubPluginSource(owner: "tddworks", repo: "asc-registry"),
        ])
    }

    // MARK: - Iris (private API, cookie-based auth)

    public func makeIrisAppBundles() -> any IrisAppBundles {
        IrisSDKAppBundles()
    }

    public func makeIrisInAppPurchaseSubmissions() -> any IrisInAppPurchaseSubmissions {
        IrisSDKInAppPurchaseSubmissions()
    }

    public func makeIrisResolutionCenter() -> any IrisResolutionCenter {
        IrisSDKResolutionCenter()
    }

    public func makeIrisCookieProvider() -> any IrisCookieProvider {
        // Resolution order: SRP-stored session (from `asc iris auth login`) first,
        // browser cookies as a fallback for users who haven't run SRP login. The
        // browser provider already handles `ASC_IRIS_COOKIES` env override internally.
        CompositeIrisCookieProvider(providers: [
            StoredSRPIrisCookieProvider(),
            BrowserIrisCookieProvider(),
        ])
    }

    func makeProvider(
        authProvider: any AuthProvider,
        requestExecutor: any RequestExecutor = DefaultRequestExecutor()
    ) throws -> APIProvider {
        let credentials = try authProvider.resolve()
        let strippedKey = credentials.privateKeyPEM
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----BEGIN EC PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END EC PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .trimmingCharacters(in: .whitespaces)
        let configuration: APIConfiguration
        if let issuerID = credentials.issuerID {
            configuration = try APIConfiguration(
                issuerID: issuerID,
                privateKeyID: credentials.keyID,
                privateKey: strippedKey
            )
        } else {
            configuration = try APIConfiguration(
                individualPrivateKeyID: credentials.keyID,
                individualPrivateKey: strippedKey
            )
        }
        return APIProvider(configuration: configuration, requestExecutor: requestExecutor)
    }
}
