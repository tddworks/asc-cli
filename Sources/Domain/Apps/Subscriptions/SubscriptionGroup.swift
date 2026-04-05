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
    public var affordances: [String: String] {
        [
            "createSubscription": "asc subscriptions create --group-id \(id) --name <name> --product-id <id> --period ONE_MONTH",
            "listSubscriptions": "asc subscriptions list --group-id \(id)",
        ]
    }
}
