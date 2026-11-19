public struct BetaAppLocalization: Sendable, Equatable, Identifiable {
    public let id: String
    /// Parent app identifier — injected by Infrastructure (ASC API omits parent IDs).
    public let appId: String
    public let locale: String
    public let description: String?
    public let feedbackEmail: String?
    public let marketingUrl: String?
    public let privacyPolicyUrl: String?
    public let tvOsPrivacyPolicy: String?

    public init(
        id: String,
        appId: String,
        locale: String,
        description: String? = nil,
        feedbackEmail: String? = nil,
        marketingUrl: String? = nil,
        privacyPolicyUrl: String? = nil,
        tvOsPrivacyPolicy: String? = nil
    ) {
        self.id = id
        self.appId = appId
        self.locale = locale
        self.description = description
        self.feedbackEmail = feedbackEmail
        self.marketingUrl = marketingUrl
        self.privacyPolicyUrl = privacyPolicyUrl
        self.tvOsPrivacyPolicy = tvOsPrivacyPolicy
    }
}

extension BetaAppLocalization: Codable {
    enum CodingKeys: String, CodingKey {
        case id, appId, locale, description, feedbackEmail
        case marketingUrl, privacyPolicyUrl, tvOsPrivacyPolicy
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        appId = try c.decode(String.self, forKey: .appId)
        locale = try c.decode(String.self, forKey: .locale)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        feedbackEmail = try c.decodeIfPresent(String.self, forKey: .feedbackEmail)
        marketingUrl = try c.decodeIfPresent(String.self, forKey: .marketingUrl)
        privacyPolicyUrl = try c.decodeIfPresent(String.self, forKey: .privacyPolicyUrl)
        tvOsPrivacyPolicy = try c.decodeIfPresent(String.self, forKey: .tvOsPrivacyPolicy)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(appId, forKey: .appId)
        try c.encode(locale, forKey: .locale)
        try c.encodeIfPresent(description, forKey: .description)
        try c.encodeIfPresent(feedbackEmail, forKey: .feedbackEmail)
        try c.encodeIfPresent(marketingUrl, forKey: .marketingUrl)
        try c.encodeIfPresent(privacyPolicyUrl, forKey: .privacyPolicyUrl)
        try c.encodeIfPresent(tvOsPrivacyPolicy, forKey: .tvOsPrivacyPolicy)
    }
}

extension BetaAppLocalization: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Locale", "Description", "Feedback Email"]
    }
    public var tableRow: [String] {
        [id, locale, description ?? "", feedbackEmail ?? ""]
    }
}

extension BetaAppLocalization: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        [
            Affordance(key: "delete", command: "beta-app-localizations", action: "delete", params: ["localization-id": id]),
            Affordance(key: "get", command: "beta-app-localizations", action: "get", params: ["localization-id": id]),
            Affordance(key: "listSiblings", command: "beta-app-localizations", action: "list", params: ["app-id": appId]),
            Affordance(key: "update", command: "beta-app-localizations", action: "update", params: ["localization-id": id]),
        ]
    }
}

public struct BetaAppLocalizationUpdate: Sendable, Equatable {
    public let description: String?
    public let feedbackEmail: String?
    public let marketingUrl: String?
    public let privacyPolicyUrl: String?
    public let tvOsPrivacyPolicy: String?

    public init(
        description: String? = nil,
        feedbackEmail: String? = nil,
        marketingUrl: String? = nil,
        privacyPolicyUrl: String? = nil,
        tvOsPrivacyPolicy: String? = nil
    ) {
        self.description = description
        self.feedbackEmail = feedbackEmail
        self.marketingUrl = marketingUrl
        self.privacyPolicyUrl = privacyPolicyUrl
        self.tvOsPrivacyPolicy = tvOsPrivacyPolicy
    }
}
