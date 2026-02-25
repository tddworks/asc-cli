public struct BetaBuildLocalization: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let buildId: String
    public let locale: String
    public let whatsNew: String?

    public init(
        id: String,
        buildId: String,
        locale: String,
        whatsNew: String? = nil
    ) {
        self.id = id
        self.buildId = buildId
        self.locale = locale
        self.whatsNew = whatsNew
    }

    private enum CodingKeys: String, CodingKey {
        case id, buildId, locale, whatsNew
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        buildId = try container.decode(String.self, forKey: .buildId)
        locale = try container.decode(String.self, forKey: .locale)
        whatsNew = try container.decodeIfPresent(String.self, forKey: .whatsNew)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(buildId, forKey: .buildId)
        try container.encode(locale, forKey: .locale)
        try container.encodeIfPresent(whatsNew, forKey: .whatsNew)
    }
}

extension BetaBuildLocalization: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "updateNotes": "asc builds update-beta-notes --build-id \(buildId) --locale \(locale) --notes <text>"
        ]
    }
}
