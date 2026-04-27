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
    public var structuredAffordances: [Affordance] {
        _ = RESTPathResolver._subscriptionPricePointRoutes
        return [
            Affordance(
                key: "listPricePoints",
                command: "subscriptions price-points",
                action: "list",
                params: ["subscription-id": subscriptionId]
            ),
        ]
    }
}
