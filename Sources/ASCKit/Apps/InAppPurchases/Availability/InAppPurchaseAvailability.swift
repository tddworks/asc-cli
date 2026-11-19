public struct InAppPurchaseAvailability: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    /// Parent IAP identifier — injected by Infrastructure since ASC API omits it from response
    public let iapId: String
    public let isAvailableInNewTerritories: Bool
    public let territories: [Territory]

    public init(
        id: String,
        iapId: String,
        isAvailableInNewTerritories: Bool,
        territories: [Territory]
    ) {
        self.id = id
        self.iapId = iapId
        self.isAvailableInNewTerritories = isAvailableInNewTerritories
        self.territories = territories
    }
}

extension InAppPurchaseAvailability: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "IAP ID", "Available in New Territories", "Territories"]
    }
    public var tableRow: [String] {
        [id, iapId, String(isAvailableInNewTerritories), territories.map(\.id).joined(separator: ", ")]
    }
}

extension InAppPurchaseAvailability: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        [
            Affordance(key: "createAvailability", command: "iap-availability", action: "create", params: ["iap-id": iapId]),
            Affordance(key: "getAvailability", command: "iap-availability", action: "get", params: ["iap-id": iapId]),
            Affordance(key: "listTerritories", command: "territories", action: "list", params: [:]),
        ]
    }
}
