public struct SubscriptionGroupLocalization: Sendable, Equatable, Identifiable {
    public let id: String
    /// Parent subscription group identifier — injected by Infrastructure
    public let groupId: String
    public let locale: String
    public let name: String?
    public let customAppName: String?
    public let state: SubscriptionGroupLocalizationState?

    public init(
        id: String,
        groupId: String,
        locale: String,
        name: String? = nil,
        customAppName: String? = nil,
        state: SubscriptionGroupLocalizationState? = nil
    ) {
        self.id = id
        self.groupId = groupId
        self.locale = locale
        self.name = name
        self.customAppName = customAppName
        self.state = state
    }
}

public enum SubscriptionGroupLocalizationState: String, Sendable, Codable, Equatable {
    case prepareForSubmission = "PREPARE_FOR_SUBMISSION"
    case waitingForReview = "WAITING_FOR_REVIEW"
    case approved = "APPROVED"
    case rejected = "REJECTED"
}

extension SubscriptionGroupLocalization: Codable {
    enum CodingKeys: String, CodingKey {
        case id, groupId, locale, name, customAppName, state
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        groupId = try c.decode(String.self, forKey: .groupId)
        locale = try c.decode(String.self, forKey: .locale)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        customAppName = try c.decodeIfPresent(String.self, forKey: .customAppName)
        state = try c.decodeIfPresent(SubscriptionGroupLocalizationState.self, forKey: .state)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(groupId, forKey: .groupId)
        try c.encode(locale, forKey: .locale)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encodeIfPresent(customAppName, forKey: .customAppName)
        try c.encodeIfPresent(state, forKey: .state)
    }
}

extension SubscriptionGroupLocalization: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Locale", "Name", "Custom App Name"]
    }
    public var tableRow: [String] {
        [id, locale, name ?? "", customAppName ?? ""]
    }
}

extension SubscriptionGroupLocalization: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        _ = RESTPathResolver._subscriptionGroupLocalizationRoutes
        return [
            Affordance(key: "delete", command: "subscription-group-localizations", action: "delete", params: ["localization-id": id]),
            Affordance(key: "listSiblings", command: "subscription-group-localizations", action: "list", params: ["group-id": groupId]),
            Affordance(key: "update", command: "subscription-group-localizations", action: "update", params: ["localization-id": id, "name": "<name>"]),
        ]
    }
}

extension RESTPathResolver {
    static let _subscriptionGroupLocalizationRoutes: Void = {
        registerRoute(
            command: "subscription-group-localizations",
            parentParam: "group-id",
            parentSegment: "subscription-groups",
            segment: "subscription-group-localizations"
        )
    }()
}
