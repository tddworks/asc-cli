/// A per-territory price entry — a value type shared by IAP and Subscription
/// price schedules.
public struct TerritoryPrice: Sendable, Equatable, Codable, Identifiable {
    public let territory: Territory
    public let customerPrice: String
    public let proceeds: String

    public var id: String { territory.id }

    public init(territory: Territory, customerPrice: String, proceeds: String) {
        self.territory = territory
        self.customerPrice = customerPrice
        self.proceeds = proceeds
    }
}

public struct InAppPurchasePriceSchedule: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    /// Parent IAP identifier — injected by Infrastructure
    public let iapId: String
    /// Base territory the developer set the price in (Apple equalizes from this).
    /// Nil when no schedule has been configured yet.
    public let baseTerritory: Territory?
    /// Per-territory prices in this schedule. Includes the manual base entry plus any
    /// auto-equalized entries the SDK adapter has fetched.
    public let territoryPrices: [TerritoryPrice]

    public init(
        id: String,
        iapId: String,
        baseTerritory: Territory? = nil,
        territoryPrices: [TerritoryPrice] = []
    ) {
        self.id = id
        self.iapId = iapId
        self.baseTerritory = baseTerritory
        self.territoryPrices = territoryPrices
    }

    /// The price at the base territory — convenience for UI headers.
    public var basePrice: TerritoryPrice? {
        guard let baseId = baseTerritory?.id else { return nil }
        return territoryPrices.first { $0.territory.id == baseId }
    }
}

extension InAppPurchasePriceSchedule {
    enum CodingKeys: String, CodingKey {
        case id, iapId, baseTerritory, territoryPrices
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        iapId = try c.decode(String.self, forKey: .iapId)
        baseTerritory = try c.decodeIfPresent(Territory.self, forKey: .baseTerritory)
        territoryPrices = try c.decodeIfPresent([TerritoryPrice].self, forKey: .territoryPrices) ?? []
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(iapId, forKey: .iapId)
        try c.encodeIfPresent(baseTerritory, forKey: .baseTerritory)
        try c.encode(territoryPrices, forKey: .territoryPrices)
    }
}

extension InAppPurchasePriceSchedule: Presentable {
    public static var tableHeaders: [String] { ["ID", "IAP ID", "Base Territory", "Territories"] }
    public var tableRow: [String] {
        [id, iapId, baseTerritory?.id ?? "", String(territoryPrices.count)]
    }
}

extension InAppPurchasePriceSchedule: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        [
            Affordance(key: "listPricePoints", command: "iap price-points", action: "list", params: ["iap-id": iapId]),
            Affordance(key: "getIAP", command: "iap", action: "get", params: ["iap-id": iapId]),
        ]
    }
}
