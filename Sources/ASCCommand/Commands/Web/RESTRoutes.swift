import Domain
import Hummingbird
import Infrastructure
import ASCPlugin
import Foundation

/// Composes all REST API v1 controllers into a single configurator.
///
/// Controllers are structs with injected dependencies (Hummingbird controller pattern).
/// Repos are created once here, not per request.
enum RESTRoutes {

    @Sendable
    static func configure(router: ASCRouter) {
        RootController().addRoutes(to: router)

        let v1 = router.group("/api/v1")

        // Create shared auth + factory once
        let auth = CompositeAuthProvider()
        let factory = ClientFactory()

        // App resource hierarchy — one focused controller per resource type.
        // Order is incidental; each controller registers its own routes.
        if let appRepo = try? factory.makeAppRepository(authProvider: auth) {
            AppsController(repo: appRepo).addRoutes(to: v1)
        }
        if let versionRepo = try? factory.makeVersionRepository(authProvider: auth) {
            VersionsController(repo: versionRepo).addRoutes(to: v1)
        }
        if let localizationRepo = try? factory.makeVersionLocalizationRepository(authProvider: auth) {
            VersionLocalizationsController(repo: localizationRepo).addRoutes(to: v1)
        }
        if let screenshotRepo = try? factory.makeScreenshotRepository(authProvider: auth) {
            ScreenshotSetsController(repo: screenshotRepo).addRoutes(to: v1)
            ScreenshotsController(repo: screenshotRepo).addRoutes(to: v1)
        }
        if let buildRepo = try? factory.makeBuildRepository(authProvider: auth) {
            BuildsController(repo: buildRepo).addRoutes(to: v1)
        }
        if let testFlightRepo = try? factory.makeTestFlightRepository(authProvider: auth) {
            TestFlightController(repo: testFlightRepo).addRoutes(to: v1)
        }
        if let reviewRepo = try? factory.makeCustomerReviewRepository(authProvider: auth) {
            CustomerReviewsController(repo: reviewRepo).addRoutes(to: v1)
        }
        if let iapRepo = try? factory.makeInAppPurchaseRepository(authProvider: auth) {
            IAPController(repo: iapRepo).addRoutes(to: v1)
        }
        if let subscriptionGroupRepo = try? factory.makeSubscriptionGroupRepository(authProvider: auth) {
            SubscriptionGroupsController(repo: subscriptionGroupRepo).addRoutes(to: v1)
        }
        if let subscriptionRepo = try? factory.makeSubscriptionRepository(authProvider: auth) {
            SubscriptionsController(repo: subscriptionRepo).addRoutes(to: v1)
        }
        if let promotedRepo = try? factory.makePromotedPurchaseRepository(authProvider: auth) {
            PromotedPurchasesController(repo: promotedRepo).addRoutes(to: v1)
        }
        if let groupLocRepo = try? factory.makeSubscriptionGroupLocalizationRepository(authProvider: auth) {
            SubscriptionGroupLocalizationsController(repo: groupLocRepo).addRoutes(to: v1)
        }
        if let promoRepo = try? factory.makeSubscriptionPromotionalOfferRepository(authProvider: auth) {
            SubscriptionPromotionalOffersController(repo: promoRepo).addRoutes(to: v1)
        }
        if let winBackRepo = try? factory.makeWinBackOfferRepository(authProvider: auth) {
            WinBackOffersController(repo: winBackRepo).addRoutes(to: v1)
        }
        if let subPriceRepo = try? factory.makeSubscriptionPriceRepository(authProvider: auth) {
            SubscriptionPricePointsController(repo: subPriceRepo).addRoutes(to: v1)
            SubscriptionPriceScheduleController(repo: subPriceRepo).addRoutes(to: v1)
            SubscriptionEqualizationsController(repo: subPriceRepo).addRoutes(to: v1)
        }
        if let iapOfferCodeRepo = try? factory.makeInAppPurchaseOfferCodeRepository(authProvider: auth),
           let subOfferCodeRepo = try? factory.makeSubscriptionOfferCodeRepository(authProvider: auth) {
            OfferCodePricesController(iapRepo: iapOfferCodeRepo, subRepo: subOfferCodeRepo).addRoutes(to: v1)
        }
        if let iapReviewRepo = try? factory.makeInAppPurchaseReviewRepository(authProvider: auth) {
            IAPReviewController(repo: iapReviewRepo).addRoutes(to: v1)
        }
        if let subReviewRepo = try? factory.makeSubscriptionReviewRepository(authProvider: auth) {
            SubscriptionReviewController(repo: subReviewRepo).addRoutes(to: v1)
        }

        // IAP detail listings
        if let iapLocRepo = try? factory.makeInAppPurchaseLocalizationRepository(authProvider: auth) {
            IAPLocalizationsController(repo: iapLocRepo).addRoutes(to: v1)
        }
        if let iapAvailRepo = try? factory.makeInAppPurchaseAvailabilityRepository(authProvider: auth) {
            IAPAvailabilityController(repo: iapAvailRepo).addRoutes(to: v1)
        }
        if let iapOfferCodeRepo = try? factory.makeInAppPurchaseOfferCodeRepository(authProvider: auth) {
            IAPOfferCodesController(repo: iapOfferCodeRepo).addRoutes(to: v1)
        }
        if let iapPriceRepo = try? factory.makeInAppPurchasePriceRepository(authProvider: auth) {
            IAPPricePointsController(repo: iapPriceRepo).addRoutes(to: v1)
            IAPPriceScheduleController(repo: iapPriceRepo).addRoutes(to: v1)
            IAPEqualizationsController(repo: iapPriceRepo).addRoutes(to: v1)
        }

        // Subscription detail listings
        if let subLocRepo = try? factory.makeSubscriptionLocalizationRepository(authProvider: auth) {
            SubscriptionLocalizationsController(repo: subLocRepo).addRoutes(to: v1)
        }
        if let subAvailRepo = try? factory.makeSubscriptionAvailabilityRepository(authProvider: auth) {
            SubscriptionAvailabilityController(repo: subAvailRepo).addRoutes(to: v1)
        }
        if let subOfferCodeRepo = try? factory.makeSubscriptionOfferCodeRepository(authProvider: auth) {
            SubscriptionOfferCodesController(repo: subOfferCodeRepo).addRoutes(to: v1)
        }
        if let subIntroRepo = try? factory.makeSubscriptionIntroductoryOfferRepository(authProvider: auth) {
            SubscriptionIntroductoryOffersController(repo: subIntroRepo).addRoutes(to: v1)
        }
        if let appInfoRepo = try? factory.makeAppInfoRepository(authProvider: auth) {
            AppInfosController(repo: appInfoRepo).addRoutes(to: v1)
        }
        if let appCategoryRepo = try? factory.makeAppCategoryRepository(authProvider: auth) {
            AppCategoriesController(repo: appCategoryRepo).addRoutes(to: v1)
        }
        if let ageRatingRepo = try? factory.makeAgeRatingDeclarationRepository(authProvider: auth) {
            AgeRatingController(repo: ageRatingRepo).addRoutes(to: v1)
        }

        // Code signing
        if let signing = try? CodeSigningController(
            certRepo: factory.makeCertificateRepository(authProvider: auth),
            bundleIDRepo: factory.makeBundleIDRepository(authProvider: auth),
            deviceRepo: factory.makeDeviceRepository(authProvider: auth),
            profileRepo: factory.makeProfileRepository(authProvider: auth)
        ) { signing.addRoutes(to: v1) }

        // Review submissions
        if let submissions = try? ReviewSubmissionsController(
            submissionRepo: factory.makeSubmissionRepository(authProvider: auth)
        ) { submissions.addRoutes(to: v1) }

        // Auth — manages the credential store the rest of the controllers consume.
        AuthController(storage: FileAuthStorage()).addRoutes(to: v1)

        // Non-authenticated resources
        SimulatorsController(repo: factory.makeSimulatorRepository()).addRoutes(to: v1)
        PluginsController(repo: factory.makePluginRepository()).addRoutes(to: v1)

        if let territories = try? TerritoriesController(
            repo: factory.makeTerritoryRepository(authProvider: auth)
        ) { territories.addRoutes(to: v1) }

        // App Shots
        AppShotsController(
            templateRepo: AggregateTemplateRepository.shared,
            themeRepo: AggregateThemeRepository.shared,
            htmlRenderer: WebKitHTMLRenderer(),
            configStorage: FileAppShotsConfigStorage(),
            galleryTemplateRepo: AggregateGalleryTemplateRepository.shared
        ).addRoutes(to: v1)
    }
}

// MARK: - Shared response helpers for all route files

/// Execute a command and return its output as a JSON response.
/// Catches errors and returns them as JSON error responses.
func restExec(_ block: () async throws -> String) async throws -> Response {
    do {
        let output = try await block()
        return restResponse(output)
    } catch {
        return jsonError(error.localizedDescription, status: .internalServerError)
    }
}

/// Returns a JSON response from a pre-encoded JSON string.
func restResponse(_ json: String, status: HTTPResponse.Status = .ok) -> Response {
    Response(
        status: status,
        headers: [.contentType: "application/json; charset=utf-8"],
        body: .init(byteBuffer: ByteBuffer(string: json))
    )
}

/// Write base64 screenshot to a temp file. Returns the file path.
func writeTempScreenshot(_ base64: String?) throws -> String {
    guard let b64 = base64, let data = Data(base64Encoded: b64) else {
        return "screenshot.png"
    }
    let tmpFile = FileManager.default.temporaryDirectory.appendingPathComponent("blitz-\(UUID().uuidString).png")
    try data.write(to: tmpFile)
    return tmpFile.path
}

/// Encode a dictionary to a JSON string.
func jsonEncode(_ dict: [String: Any]) -> String {
    guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys]) else { return "{}" }
    return String(data: data, encoding: .utf8) ?? "{}"
}

/// Format Presentable domain models as a REST JSON response.
/// This is the REST equivalent of CLI's `formatter.formatAgentItems(items)`.
func restFormat<T: Encodable & AffordanceProviding & Presentable>(
    _ items: [T]
) throws -> Response {
    let formatter = OutputFormatter(format: .json, pretty: true)
    return restResponse(try formatter.formatAgentItems(items, affordanceMode: .rest))
}

/// Format a single Presentable domain model as a REST JSON response.
func restFormat<T: Encodable & AffordanceProviding & Presentable>(
    _ item: T
) throws -> Response {
    try restFormat([item])
}
