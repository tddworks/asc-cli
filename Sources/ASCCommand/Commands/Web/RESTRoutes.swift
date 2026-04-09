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

        // Apps & child resources
        if let apps = try? AppsController(
            appRepo: factory.makeAppRepository(authProvider: auth),
            versionRepo: factory.makeVersionRepository(authProvider: auth),
            localizationRepo: factory.makeVersionLocalizationRepository(authProvider: auth),
            buildRepo: factory.makeBuildRepository(authProvider: auth),
            testFlightRepo: factory.makeTestFlightRepository(authProvider: auth),
            reviewRepo: factory.makeCustomerReviewRepository(authProvider: auth),
            iapRepo: factory.makeInAppPurchaseRepository(authProvider: auth),
            subscriptionGroupRepo: factory.makeSubscriptionGroupRepository(authProvider: auth)
        ) { apps.addRoutes(to: v1) }

        // Code signing
        if let signing = try? CodeSigningController(
            certRepo: factory.makeCertificateRepository(authProvider: auth),
            bundleIDRepo: factory.makeBundleIDRepository(authProvider: auth),
            deviceRepo: factory.makeDeviceRepository(authProvider: auth),
            profileRepo: factory.makeProfileRepository(authProvider: auth)
        ) { signing.addRoutes(to: v1) }

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
