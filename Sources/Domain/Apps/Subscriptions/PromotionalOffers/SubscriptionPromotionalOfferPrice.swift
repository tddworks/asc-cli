public struct SubscriptionPromotionalOfferPrice: Sendable, Equatable, Identifiable {
    public let id: String
    /// Parent promotional offer identifier — injected by Infrastructure
    public let offerId: String
    public let territory: String?
    public let subscriptionPricePointId: String?

    public init(id: String, offerId: String, territory: String? = nil, subscriptionPricePointId: String? = nil) {
        self.id = id
        self.offerId = offerId
        self.territory = territory
        self.subscriptionPricePointId = subscriptionPricePointId
    }
}

extension SubscriptionPromotionalOfferPrice: Codable {
    enum CodingKeys: String, CodingKey {
        case id, offerId, territory, subscriptionPricePointId
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        offerId = try c.decode(String.self, forKey: .offerId)
        territory = try c.decodeIfPresent(String.self, forKey: .territory)
        subscriptionPricePointId = try c.decodeIfPresent(String.self, forKey: .subscriptionPricePointId)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(offerId, forKey: .offerId)
        try c.encodeIfPresent(territory, forKey: .territory)
        try c.encodeIfPresent(subscriptionPricePointId, forKey: .subscriptionPricePointId)
    }
}

extension SubscriptionPromotionalOfferPrice: Presentable {
    public static var tableHeaders: [String] { ["ID", "Territory", "Price Point ID"] }
    public var tableRow: [String] { [id, territory ?? "", subscriptionPricePointId ?? ""] }
}

extension SubscriptionPromotionalOfferPrice: AffordanceProviding {
    public var affordances: [String: String] {
        ["listPrices": "asc subscription-promotional-offers prices list --offer-id \(offerId)"]
    }
}

/// Per-territory price input for creating a promotional offer
public struct PromotionalOfferPriceInput: Sendable, Equatable {
    public let territory: String
    public let pricePointId: String

    public init(territory: String, pricePointId: String) {
        self.territory = territory
        self.pricePointId = pricePointId
    }
}
