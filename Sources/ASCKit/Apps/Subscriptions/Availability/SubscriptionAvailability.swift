public struct SubscriptionAvailability: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    /// Parent subscription identifier — injected by Infrastructure since ASC API omits it from response
    public let subscriptionId: String
    public let isAvailableInNewTerritories: Bool
    public let territories: [Territory]

    public init(
        id: String,
        subscriptionId: String,
        isAvailableInNewTerritories: Bool,
        territories: [Territory]
    ) {
        self.id = id
        self.subscriptionId = subscriptionId
        self.isAvailableInNewTerritories = isAvailableInNewTerritories
        self.territories = territories
    }
}

extension SubscriptionAvailability: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Subscription ID", "Available in New Territories", "Territories"]
    }
    public var tableRow: [String] {
        [id, subscriptionId, String(isAvailableInNewTerritories), territories.map(\.id).joined(separator: ", ")]
    }
}

extension SubscriptionAvailability: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        [
            Affordance(key: "createAvailability", command: "subscription-availability", action: "create", params: ["subscription-id": subscriptionId]),
            Affordance(key: "getAvailability", command: "subscription-availability", action: "get", params: ["subscription-id": subscriptionId]),
            Affordance(key: "listTerritories", command: "territories", action: "list", params: [:]),
        ]
    }
}
