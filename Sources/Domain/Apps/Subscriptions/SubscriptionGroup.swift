public struct SubscriptionGroup: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    /// Parent app identifier — injected by Infrastructure since ASC API omits it from response
    public let appId: String
    public let referenceName: String

    public init(id: String, appId: String, referenceName: String) {
        self.id = id
        self.appId = appId
        self.referenceName = referenceName
    }
}

extension SubscriptionGroup: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Reference Name"]
    }
    public var tableRow: [String] {
        [id, referenceName]
    }
}

extension SubscriptionGroup: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        [
            Affordance(key: "createLocalization", command: "subscription-group-localizations", action: "create",
                       params: ["group-id": id, "locale": "en-US", "name": "<name>"]),
            Affordance(key: "createSubscription", command: "subscriptions", action: "create",
                       params: ["group-id": id, "name": "<name>", "product-id": "<id>", "period": "ONE_MONTH"]),
            Affordance(key: "delete", command: "subscription-groups", action: "delete",
                       params: ["group-id": id]),
            Affordance(key: "listLocalizations", command: "subscription-group-localizations", action: "list",
                       params: ["group-id": id]),
            Affordance(key: "listSubscriptions", command: "subscriptions", action: "list",
                       params: ["group-id": id]),
            Affordance(key: "update", command: "subscription-groups", action: "update",
                       params: ["group-id": id, "reference-name": "<name>"]),
        ]
    }
}
