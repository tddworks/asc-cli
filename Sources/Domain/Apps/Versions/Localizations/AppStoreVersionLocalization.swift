public struct AppStoreVersionLocalization: Sendable, Equatable, Identifiable {
    public let id: String
    /// Parent version identifier — always present so agents can correlate responses.
    public let versionId: String
    public let locale: String
    public let whatsNew: String?
    public let description: String?
    public let keywords: String?
    public let marketingUrl: String?
    public let supportUrl: String?
    public let promotionalText: String?

    public init(
        id: String,
        versionId: String,
        locale: String,
        whatsNew: String? = nil,
        description: String? = nil,
        keywords: String? = nil,
        marketingUrl: String? = nil,
        supportUrl: String? = nil,
        promotionalText: String? = nil
    ) {
        self.id = id
        self.versionId = versionId
        self.locale = locale
        self.whatsNew = whatsNew
        self.description = description
        self.keywords = keywords
        self.marketingUrl = marketingUrl
        self.supportUrl = supportUrl
        self.promotionalText = promotionalText
    }
}

// MARK: - Codable (omit nil optional fields from JSON output)

extension AppStoreVersionLocalization: Codable {
    enum CodingKeys: String, CodingKey {
        case id, versionId, locale
        case whatsNew, description, keywords, marketingUrl, supportUrl, promotionalText
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        versionId = try c.decode(String.self, forKey: .versionId)
        locale = try c.decode(String.self, forKey: .locale)
        whatsNew = try c.decodeIfPresent(String.self, forKey: .whatsNew)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        keywords = try c.decodeIfPresent(String.self, forKey: .keywords)
        marketingUrl = try c.decodeIfPresent(String.self, forKey: .marketingUrl)
        supportUrl = try c.decodeIfPresent(String.self, forKey: .supportUrl)
        promotionalText = try c.decodeIfPresent(String.self, forKey: .promotionalText)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(versionId, forKey: .versionId)
        try c.encode(locale, forKey: .locale)
        try c.encodeIfPresent(whatsNew, forKey: .whatsNew)
        try c.encodeIfPresent(description, forKey: .description)
        try c.encodeIfPresent(keywords, forKey: .keywords)
        try c.encodeIfPresent(marketingUrl, forKey: .marketingUrl)
        try c.encodeIfPresent(supportUrl, forKey: .supportUrl)
        try c.encodeIfPresent(promotionalText, forKey: .promotionalText)
    }
}

// MARK: - Presentable

extension AppStoreVersionLocalization: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Locale", "Description", "Keywords"]
    }
    public var tableRow: [String] {
        [id, locale, description ?? "", keywords ?? ""]
    }
}

// MARK: - AffordanceProviding

extension AppStoreVersionLocalization: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        [
            Affordance(key: "listScreenshotSets", command: "screenshot-sets", action: "list", params: ["localization-id": id]),
            Affordance(key: "listLocalizations", command: "version-localizations", action: "list", params: ["version-id": versionId]),
            Affordance(key: "updateLocalization", command: "version-localizations", action: "update", params: ["localization-id": id]),
        ]
    }
}
