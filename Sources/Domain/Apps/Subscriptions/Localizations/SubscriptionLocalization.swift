public struct SubscriptionLocalization: Sendable, Equatable, Identifiable {
    public let id: String
    /// Parent subscription identifier — injected by Infrastructure since ASC API omits it from response
    public let subscriptionId: String
    public let locale: String
    public let name: String?
    public let description: String?
    public let state: SubscriptionLocalizationState?

    public init(
        id: String,
        subscriptionId: String,
        locale: String,
        name: String? = nil,
        description: String? = nil,
        state: SubscriptionLocalizationState? = nil
    ) {
        self.id = id
        self.subscriptionId = subscriptionId
        self.locale = locale
        self.name = name
        self.description = description
        self.state = state
    }
}

public enum SubscriptionLocalizationState: String, Sendable, Codable, Equatable {
    case prepareForSubmission = "PREPARE_FOR_SUBMISSION"
    case waitingForReview = "WAITING_FOR_REVIEW"
    case approved = "APPROVED"
    case rejected = "REJECTED"
}

extension SubscriptionLocalization: Codable {
    enum CodingKeys: String, CodingKey {
        case id, subscriptionId, locale, name, description, state
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        subscriptionId = try c.decode(String.self, forKey: .subscriptionId)
        locale = try c.decode(String.self, forKey: .locale)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        state = try c.decodeIfPresent(SubscriptionLocalizationState.self, forKey: .state)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(subscriptionId, forKey: .subscriptionId)
        try c.encode(locale, forKey: .locale)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encodeIfPresent(description, forKey: .description)
        try c.encodeIfPresent(state, forKey: .state)
    }
}

extension SubscriptionLocalization: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Locale", "Name", "Description"]
    }
    public var tableRow: [String] {
        [id, locale, name ?? "", description ?? ""]
    }
}

extension SubscriptionLocalization: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "listSiblings": "asc subscription-localizations list --subscription-id \(subscriptionId)",
        ]
    }
}
