import Foundation

public final class AppScreenshotSet: Identifiable, @unchecked Sendable {
    public let id: String
    /// Parent localization identifier — always present so agents can correlate responses.
    public let localizationId: String
    public let screenshotDisplayType: ScreenshotDisplayType
    public let screenshotsCount: Int

    private let repo: (any ScreenshotRepository)?

    public init(
        id: String,
        localizationId: String,
        screenshotDisplayType: ScreenshotDisplayType,
        screenshotsCount: Int = 0,
        repo: (any ScreenshotRepository)? = nil
    ) {
        self.id = id
        self.localizationId = localizationId
        self.screenshotDisplayType = screenshotDisplayType
        self.screenshotsCount = screenshotsCount
        self.repo = repo
    }

    public var isEmpty: Bool { screenshotsCount == 0 }
    public var deviceCategory: ScreenshotDisplayType.DeviceCategory { screenshotDisplayType.deviceCategory }
    public var displayTypeName: String { screenshotDisplayType.displayName }

    // MARK: - Domain Operation

    public func importScreenshots(
        entries: [ScreenshotManifest.ScreenshotEntry],
        imageURLs: [String: URL]
    ) async throws -> [AppScreenshot] {
        guard let repo else {
            throw APIError.unknown("importScreenshots requires a repository — use the set returned by listScreenshotSets or createScreenshotSet")
        }
        var results: [AppScreenshot] = []
        for entry in entries.sorted(by: { $0.order < $1.order }) {
            guard let url = imageURLs[entry.file] else { continue }
            let screenshot = try await repo.uploadScreenshot(setId: id, fileURL: url)
            results.append(screenshot)
        }
        return results
    }
}

// MARK: - Equatable (value fields only — repo excluded)

extension AppScreenshotSet: Equatable {
    public static func == (lhs: AppScreenshotSet, rhs: AppScreenshotSet) -> Bool {
        lhs.id == rhs.id &&
        lhs.localizationId == rhs.localizationId &&
        lhs.screenshotDisplayType == rhs.screenshotDisplayType &&
        lhs.screenshotsCount == rhs.screenshotsCount
    }
}

// MARK: - Codable (value fields only — repo excluded from JSON schema)

extension AppScreenshotSet: Codable {
    enum CodingKeys: String, CodingKey {
        case id, localizationId, screenshotDisplayType, screenshotsCount
    }

    public convenience init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try c.decode(String.self, forKey: .id),
            localizationId: try c.decode(String.self, forKey: .localizationId),
            screenshotDisplayType: try c.decode(ScreenshotDisplayType.self, forKey: .screenshotDisplayType),
            screenshotsCount: try c.decode(Int.self, forKey: .screenshotsCount)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(localizationId, forKey: .localizationId)
        try c.encode(screenshotDisplayType, forKey: .screenshotDisplayType)
        try c.encode(screenshotsCount, forKey: .screenshotsCount)
    }
}

// MARK: - AffordanceProviding

extension AppScreenshotSet: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "listScreenshots": "asc screenshots list --set-id \(id)",
            "listScreenshotSets": "asc screenshot-sets list --localization-id \(localizationId)",
        ]
    }
}