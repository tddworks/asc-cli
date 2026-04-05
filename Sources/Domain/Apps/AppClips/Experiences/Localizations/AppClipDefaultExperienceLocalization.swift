public struct AppClipDefaultExperienceLocalization: Sendable, Equatable, Identifiable {
    public let id: String
    public let experienceId: String
    public let locale: String
    public let subtitle: String?

    public init(id: String, experienceId: String, locale: String, subtitle: String? = nil) {
        self.id = id
        self.experienceId = experienceId
        self.locale = locale
        self.subtitle = subtitle
    }
}

extension AppClipDefaultExperienceLocalization: Codable {
    enum CodingKeys: String, CodingKey {
        case id, experienceId, locale, subtitle
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        experienceId = try container.decode(String.self, forKey: .experienceId)
        locale = try container.decode(String.self, forKey: .locale)
        subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(experienceId, forKey: .experienceId)
        try container.encode(locale, forKey: .locale)
        try container.encodeIfPresent(subtitle, forKey: .subtitle)
    }
}

extension AppClipDefaultExperienceLocalization: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Experience ID", "Locale", "Subtitle"]
    }
    public var tableRow: [String] {
        [id, experienceId, locale, subtitle ?? ""]
    }
}

extension AppClipDefaultExperienceLocalization: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "delete": "asc app-clip-experience-localizations delete --localization-id \(id)",
            "listLocalizations": "asc app-clip-experience-localizations list --experience-id \(experienceId)",
        ]
    }
}
