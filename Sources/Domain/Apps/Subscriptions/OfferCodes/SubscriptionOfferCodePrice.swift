public struct SubscriptionOfferCodePrice: Sendable, Equatable, Identifiable {
    public let id: String
    /// Parent offer code identifier — injected by Infrastructure
    public let offerCodeId: String
    public let territory: String?
    public let subscriptionPricePointId: String?

    public init(id: String, offerCodeId: String, territory: String? = nil, subscriptionPricePointId: String? = nil) {
        self.id = id
        self.offerCodeId = offerCodeId
        self.territory = territory
        self.subscriptionPricePointId = subscriptionPricePointId
    }
}

extension SubscriptionOfferCodePrice: Codable {
    enum CodingKeys: String, CodingKey {
        case id, offerCodeId, territory, subscriptionPricePointId
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        offerCodeId = try c.decode(String.self, forKey: .offerCodeId)
        territory = try c.decodeIfPresent(String.self, forKey: .territory)
        subscriptionPricePointId = try c.decodeIfPresent(String.self, forKey: .subscriptionPricePointId)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(offerCodeId, forKey: .offerCodeId)
        try c.encodeIfPresent(territory, forKey: .territory)
        try c.encodeIfPresent(subscriptionPricePointId, forKey: .subscriptionPricePointId)
    }
}

extension SubscriptionOfferCodePrice: Presentable {
    public static var tableHeaders: [String] { ["ID", "Territory", "Price Point ID"] }
    public var tableRow: [String] { [id, territory ?? "", subscriptionPricePointId ?? ""] }
}

extension SubscriptionOfferCodePrice: AffordanceProviding {
    public var affordances: [String: String] {
        ["listPrices": "asc subscription-offer-codes prices list --offer-code-id \(offerCodeId)"]
    }
}
