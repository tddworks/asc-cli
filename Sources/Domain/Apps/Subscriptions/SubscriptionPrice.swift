public struct SubscriptionPrice: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    /// Parent subscription identifier — injected by Infrastructure
    public let subscriptionId: String

    public init(id: String, subscriptionId: String) {
        self.id = id
        self.subscriptionId = subscriptionId
    }
}

extension SubscriptionPrice: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Subscription ID"]
    }
    public var tableRow: [String] {
        [id, subscriptionId]
    }
}

extension SubscriptionPrice: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "listPricePoints": "asc subscriptions price-points list --subscription-id \(subscriptionId)",
        ]
    }
}
