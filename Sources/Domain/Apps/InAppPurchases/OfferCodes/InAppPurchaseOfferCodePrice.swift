public struct InAppPurchaseOfferCodePrice: Sendable, Equatable, Identifiable {
    public let id: String
    /// Parent offer code identifier — injected by Infrastructure
    public let offerCodeId: String
    public let territory: String?
    public let pricePointId: String?

    public init(id: String, offerCodeId: String, territory: String? = nil, pricePointId: String? = nil) {
        self.id = id
        self.offerCodeId = offerCodeId
        self.territory = territory
        self.pricePointId = pricePointId
    }
}

extension InAppPurchaseOfferCodePrice: Codable {
    enum CodingKeys: String, CodingKey {
        case id, offerCodeId, territory, pricePointId
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        offerCodeId = try c.decode(String.self, forKey: .offerCodeId)
        territory = try c.decodeIfPresent(String.self, forKey: .territory)
        pricePointId = try c.decodeIfPresent(String.self, forKey: .pricePointId)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(offerCodeId, forKey: .offerCodeId)
        try c.encodeIfPresent(territory, forKey: .territory)
        try c.encodeIfPresent(pricePointId, forKey: .pricePointId)
    }
}

extension InAppPurchaseOfferCodePrice: Presentable {
    public static var tableHeaders: [String] { ["ID", "Territory", "Price Point ID"] }
    public var tableRow: [String] { [id, territory ?? "", pricePointId ?? ""] }
}

extension InAppPurchaseOfferCodePrice: AffordanceProviding {
    public var affordances: [String: String] {
        ["listPrices": "asc iap-offer-codes prices list --offer-code-id \(offerCodeId)"]
    }
}
