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
            SubscriptionPricesController(repo: subPriceRepo).addRoutes(to: v1)
        }
        if let iapOfferCodeRepo = try? factory.makeInAppPurchaseOfferCodeRepository(authProvider: auth),
           let subOfferCodeRepo = try? factory.makeSubscriptionOfferCodeRepository(authProvider: auth) {
            OfferCodePricesController(iapRepo: iapOfferCodeRepo, subRepo: subOfferCodeRepo).addRoutes(to: v1)
        }
        if let iapOfferCodeRepo = try? factory.makeInAppPurchaseOfferCodeRepository(authProvider: auth) {
            IAPOfferCodeOneTimeCodesController(repo: iapOfferCodeRepo).addRoutes(to: v1)
        }
        if let subOfferCodeRepo = try? factory.makeSubscriptionOfferCodeRepository(authProvider: auth) {
            SubscriptionOfferCodeOneTimeCodesController(repo: subOfferCodeRepo).addRoutes(to: v1)
        }
        if let iapReviewRepo = try? factory.makeInAppPurchaseReviewRepository(authProvider: auth) {
            IAPReviewController(repo: iapReviewRepo).addRoutes(to: v1)
        }
        if let subReviewRepo = try? factory.makeSubscriptionReviewRepository(authProvider: auth) {
            SubscriptionReviewController(repo: subReviewRepo).addRoutes(to: v1)
        }
        if let iapSubmissionRepo = try? factory.makeInAppPurchaseSubmissionRepository(authProvider: auth) {
            IAPSubmissionController(repo: iapSubmissionRepo).addRoutes(to: v1)
        }
        if let subSubmissionRepo = try? factory.makeSubscriptionSubmissionRepository(authProvider: auth) {
            SubscriptionSubmissionController(repo: subSubmissionRepo).addRoutes(to: v1)
        }

        // IAP detail listings
        if let iapLocRepo = try? factory.makeInAppPurchaseLocalizationRepository(authProvider: auth) {
            IAPLocalizationsController(repo: iapLocRepo).addRoutes(to: v1)
        }
        if let iapAvailRepo = try? factory.makeInAppPurchaseAvailabilityRepository(authProvider: auth),
           let territoryRepo = try? factory.makeTerritoryRepository(authProvider: auth) {
            IAPAvailabilityController(repo: iapAvailRepo, territoryRepo: territoryRepo).addRoutes(to: v1)
        }
        if let iapOfferCodeRepo = try? factory.makeInAppPurchaseOfferCodeRepository(authProvider: auth) {
            IAPOfferCodesController(repo: iapOfferCodeRepo).addRoutes(to: v1)
        }
        if let iapPriceRepo = try? factory.makeInAppPurchasePriceRepository(authProvider: auth) {
            IAPPricePointsController(repo: iapPriceRepo).addRoutes(to: v1)
            IAPPriceScheduleController(repo: iapPriceRepo).addRoutes(to: v1)
            IAPEqualizationsController(repo: iapPriceRepo).addRoutes(to: v1)
            IAPPricesController(repo: iapPriceRepo).addRoutes(to: v1)
        }

        // Subscription detail listings
        if let subLocRepo = try? factory.makeSubscriptionLocalizationRepository(authProvider: auth) {
            SubscriptionLocalizationsController(repo: subLocRepo).addRoutes(to: v1)
        }
        if let subAvailRepo = try? factory.makeSubscriptionAvailabilityRepository(authProvider: auth),
           let territoryRepo = try? factory.makeTerritoryRepository(authProvider: auth) {
            SubscriptionAvailabilityController(repo: subAvailRepo, territoryRepo: territoryRepo).addRoutes(to: v1)
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

/// Collect a request's raw body bytes (up to ~20MB), spool to a temp file with the
/// given extension, run `upload(fileURL:)`, and clean up the temp file. The temp
/// is removed even if `upload` throws — keeps the spool directory bounded.
///
/// Auto-detects `multipart/form-data` (the shape browser `<input type=file>` posts)
/// and extracts the first file part's bytes before spooling. Forwarding the multipart
/// envelope to ASC otherwise yields `IMAGE_CORRUPT` because the boundary lines aren't
/// part of a valid PNG/JPEG.
///
/// Used for review screenshots and 1024×1024 promotional images. The 20MB ceiling
/// covers the largest screenshot Apple accepts (~10MB) with headroom.
func uploadReviewBody<T>(
    request: Request,
    fileExtension: String,
    upload: (URL) async throws -> T
) async throws -> T {
    let buffer = try await request.body.collect(upTo: 20 * 1024 * 1024)
    let rawBytes = Data(buffer: buffer)

    let contentType = request.headers[.contentType]
    let (fileBytes, resolvedExtension, originalFilename): (Data, String, String?)
    if let boundary = multipartBoundary(from: contentType),
       let part = extractMultipartFilePart(body: rawBytes, boundary: boundary) {
        // Multipart: prefer the inner part's Content-Type for extension hinting,
        // otherwise the filename's extension, otherwise the caller's fallback.
        let extFromInner = extensionFor(contentType: part.contentType, fallback: fileExtension)
        let extFromFilename = part.filename.flatMap { ($0 as NSString).pathExtension.lowercased() }
        let resolvedExt = (extFromFilename.flatMap { $0.isEmpty ? nil : $0 }) ?? extFromInner
        (fileBytes, resolvedExtension, originalFilename) = (part.bytes, resolvedExt, part.filename)
    } else {
        (fileBytes, resolvedExtension, originalFilename) = (rawBytes, fileExtension, nil)
    }

    // Spool into a per-request UUID subdirectory so `lastPathComponent` is the user-supplied
    // filename without any temp-dir collision risk. ASC stores `attributes.fileName` from
    // the upload reservation — sending a generic "upload-{UUID}.png" makes ASC's review-asset
    // UI fall back to "SOURCE" / "No preview" because it can't infer the file type.
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: dir) }

    let preferredName = originalFilename
        .map { $0.replacingOccurrences(of: "/", with: "_") }
        .flatMap { $0.isEmpty ? nil : $0 } ?? "upload.\(resolvedExtension)"
    let tmpURL = dir.appendingPathComponent(preferredName)
    try fileBytes.write(to: tmpURL)

    // Diagnostic to stderr so the upload pipeline is visible in `swift run asc web-server`
    // console output. Helps diagnose IMAGE_CORRUPT vs filename-rendering issues without
    // having to keep temp files around.
    let magic = fileBytes.prefix(16).map { String(format: "%02X", $0) }.joined(separator: " ")
    let summary = """
    [upload] contentType=\(contentType ?? "nil") rawBytes=\(rawBytes.count) extractedBytes=\(fileBytes.count)
    [upload] filename=\(preferredName) ext=\(resolvedExtension) first16=\(magic)
    [upload] tmpFile=\(tmpURL.path)

    """
    FileHandle.standardError.write(Data(summary.utf8))

    return try await upload(tmpURL)
}

/// Wraps `uploadReviewBody` in a do/catch so failures (auth, ASC processing failure,
/// poll timeout, body too large) surface as a JSON error response with a logged message
/// instead of an unhandled throw becoming a Hummingbird 500-with-empty-body. The `label`
/// is prefixed in stderr logs so we can correlate without enabling debug logging.
func uploadReviewBodyResponse<T: Encodable & AffordanceProviding & Presentable>(
    label: String,
    request: Request,
    fileExtension: String,
    upload: (URL) async throws -> T
) async -> Response {
    do {
        let item = try await uploadReviewBody(
            request: request, fileExtension: fileExtension, upload: upload
        )
        return try restFormat(item)
    } catch {
        let message = "\(label) upload failed: \(error)"
        FileHandle.standardError.write(Data((message + "\n").utf8))
        return jsonError(message, status: .internalServerError)
    }
}

// MARK: - Multipart/form-data parsing
//
// Browser `<input type=file>` (and `FormData`) wraps file bytes in a multipart envelope
// even when there's only one field. Forwarding that envelope to ASC results in
// `IMAGE_CORRUPT` because the boundary lines and Content-Disposition headers aren't
// part of a valid PNG/JPEG. We strip them before spooling to the upload temp file.

/// Pulls the boundary token out of a `multipart/form-data; boundary=…` Content-Type.
/// Returns `nil` for any other content type. Tolerates surrounding quotes and casing.
func multipartBoundary(from contentType: String?) -> String? {
    guard let contentType else { return nil }
    let lower = contentType.lowercased()
    guard lower.contains("multipart/form-data") else { return nil }
    for part in contentType.split(separator: ";") {
        let trimmed = part.trimmingCharacters(in: .whitespaces)
        if trimmed.lowercased().hasPrefix("boundary=") {
            var value = String(trimmed.dropFirst("boundary=".count))
            if value.hasPrefix("\""), value.hasSuffix("\"") {
                value = String(value.dropFirst().dropLast())
            }
            return value.isEmpty ? nil : value
        }
    }
    return nil
}

/// Extracts the first part's bytes (and its Content-Type / filename when declared)
/// from a `multipart/form-data` body. Designed for the single-file upload case the
/// browser sends — we don't need to enumerate all parts.
///
/// Byte-safe: searches for boundary markers via byte ranges, never decoding the body
/// as a string. Embedded CRLF inside the file bytes are preserved.
func extractMultipartFilePart(body: Data, boundary: String) -> (bytes: Data, contentType: String?, filename: String?)? {
    let dashBoundary = Data("--\(boundary)".utf8)
    let crlfCrlf = Data("\r\n\r\n".utf8)

    guard let firstBoundary = body.range(of: dashBoundary) else { return nil }
    let afterBoundary = firstBoundary.upperBound
    guard afterBoundary < body.endIndex else { return nil }

    // Headers run from end-of-first-boundary-line to the next CRLFCRLF.
    let headerSearch = afterBoundary..<body.endIndex
    guard let headerEnd = body.range(of: crlfCrlf, in: headerSearch) else { return nil }

    let headerBlock = body[afterBoundary..<headerEnd.lowerBound]
    let headerString = String(data: headerBlock, encoding: .utf8) ?? ""
    let (contentType, filename) = parseMultipartPartHeaders(headerString)

    // File body runs from after the CRLFCRLF until the next boundary line. The two
    // bytes immediately before the next boundary are the trailing `\r\n` separator
    // and don't belong to the file.
    let bodyStart = headerEnd.upperBound
    let bodySearch = bodyStart..<body.endIndex
    guard let nextBoundary = body.range(of: dashBoundary, in: bodySearch) else { return nil }
    let bodyEnd = nextBoundary.lowerBound - 2
    guard bodyEnd >= bodyStart else { return nil }

    return (bytes: body.subdata(in: bodyStart..<bodyEnd), contentType: contentType, filename: filename)
}

/// Reads `Content-Type` and `filename="…"` from a multipart part's header block.
private func parseMultipartPartHeaders(_ headerString: String) -> (contentType: String?, filename: String?) {
    var contentType: String?
    var filename: String?
    for line in headerString.split(separator: "\r\n", omittingEmptySubsequences: true) {
        let lower = line.lowercased()
        if lower.hasPrefix("content-type:") {
            contentType = line.dropFirst("content-type:".count).trimmingCharacters(in: .whitespaces)
        } else if lower.hasPrefix("content-disposition:") {
            // Naive: filename="something.png"
            if let range = line.range(of: "filename=\"") {
                let after = line[range.upperBound...]
                if let end = after.firstIndex(of: "\"") {
                    filename = String(after[..<end])
                }
            }
        }
    }
    return (contentType, filename)
}

/// Pick a file extension based on `Content-Type`. Falls back to the caller's default
/// when the header is absent or carries an unfamiliar mime-type.
func extensionFor(contentType: String?, fallback: String) -> String {
    guard let ct = contentType?.lowercased() else { return fallback }
    if ct.contains("image/png") { return "png" }
    if ct.contains("image/jpeg") || ct.contains("image/jpg") { return "jpg" }
    if ct.contains("image/heic") { return "heic" }
    if ct.contains("image/webp") { return "webp" }
    return fallback
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

/// Paginated REST response: `{ data: [...], nextCursor: "...", totalCount: N }`.
/// `nextCursor`/`totalCount` are omitted when nil. Frontends loop until `nextCursor` is absent.
func restFormatPaginated<T: Encodable & AffordanceProviding & Presentable>(
    _ response: PaginatedResponse<T>
) throws -> Response {
    let formatter = OutputFormatter(format: .json, pretty: true)
    return restResponse(try formatter.formatAgentPaginated(response, affordanceMode: .rest))
}
