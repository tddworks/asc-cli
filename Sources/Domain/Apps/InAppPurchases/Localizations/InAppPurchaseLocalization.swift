public struct InAppPurchaseLocalization: Sendable, Equatable, Identifiable {
    public let id: String
    /// Parent IAP identifier — injected by Infrastructure since ASC API omits it from response
    public let iapId: String
    public let locale: String
    public let name: String?
    public let description: String?
    public let state: InAppPurchaseLocalizationState?

    public init(
        id: String,
        iapId: String,
        locale: String,
        name: String? = nil,
        description: String? = nil,
        state: InAppPurchaseLocalizationState? = nil
    ) {
        self.id = id
        self.iapId = iapId
        self.locale = locale
        self.name = name
        self.description = description
        self.state = state
    }
}

public enum InAppPurchaseLocalizationState: String, Sendable, Codable, Equatable {
    case prepareForSubmission = "PREPARE_FOR_SUBMISSION"
    case waitingForReview = "WAITING_FOR_REVIEW"
    case approved = "APPROVED"
    case rejected = "REJECTED"
}

extension InAppPurchaseLocalization: Codable {
    enum CodingKeys: String, CodingKey {
        case id, iapId, locale, name, description, state
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        iapId = try c.decode(String.self, forKey: .iapId)
        locale = try c.decode(String.self, forKey: .locale)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        state = try c.decodeIfPresent(InAppPurchaseLocalizationState.self, forKey: .state)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(iapId, forKey: .iapId)
        try c.encode(locale, forKey: .locale)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encodeIfPresent(description, forKey: .description)
        try c.encodeIfPresent(state, forKey: .state)
    }
}

extension InAppPurchaseLocalization: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Locale", "Name", "Description"]
    }
    public var tableRow: [String] {
        [id, locale, name ?? "", description ?? ""]
    }
}

extension InAppPurchaseLocalization: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "delete": "asc iap-localizations delete --localization-id \(id)",
            "listSiblings": "asc iap-localizations list --iap-id \(iapId)",
            "update": "asc iap-localizations update --localization-id \(id) --name <name>",
        ]
    }
}
