public struct SubscriptionPricePoint: Sendable, Equatable, Identifiable {
    public let id: String
    /// Parent subscription identifier — injected by Infrastructure
    public let subscriptionId: String
    public let territory: String?
    public let customerPrice: String?
    public let proceeds: String?
    public let proceedsYear2: String?

    public init(
        id: String,
        subscriptionId: String,
        territory: String? = nil,
        customerPrice: String? = nil,
        proceeds: String? = nil,
        proceedsYear2: String? = nil
    ) {
        self.id = id
        self.subscriptionId = subscriptionId
        self.territory = territory
        self.customerPrice = customerPrice
        self.proceeds = proceeds
        self.proceedsYear2 = proceedsYear2
    }
}

extension SubscriptionPricePoint: Codable {
    enum CodingKeys: String, CodingKey {
        case id, subscriptionId, territory, customerPrice, proceeds, proceedsYear2
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        subscriptionId = try c.decode(String.self, forKey: .subscriptionId)
        territory = try c.decodeIfPresent(String.self, forKey: .territory)
        customerPrice = try c.decodeIfPresent(String.self, forKey: .customerPrice)
        proceeds = try c.decodeIfPresent(String.self, forKey: .proceeds)
        proceedsYear2 = try c.decodeIfPresent(String.self, forKey: .proceedsYear2)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(subscriptionId, forKey: .subscriptionId)
        try c.encodeIfPresent(territory, forKey: .territory)
        try c.encodeIfPresent(customerPrice, forKey: .customerPrice)
        try c.encodeIfPresent(proceeds, forKey: .proceeds)
        try c.encodeIfPresent(proceedsYear2, forKey: .proceedsYear2)
    }
}

extension SubscriptionPricePoint: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Territory", "Customer Price", "Proceeds", "Year 2 Proceeds"]
    }
    public var tableRow: [String] {
        [id, territory ?? "", customerPrice ?? "", proceeds ?? "", proceedsYear2 ?? ""]
    }
}

extension SubscriptionPricePoint: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        _ = RESTPathResolver._subscriptionPricePointRoutes
        var items: [Affordance] = [
            Affordance(key: "listPricePoints", command: "subscriptions price-points", action: "list", params: ["subscription-id": subscriptionId]),
        ]
        if let territory {
            items.append(Affordance(
                key: "setPrice",
                command: "subscriptions prices",
                action: "set",
                params: ["subscription-id": subscriptionId, "territory": territory, "price-point-id": id]
            ))
        }
        return items
    }
}

extension RESTPathResolver {
    static let _subscriptionPricePointRoutes: Void = {
        registerRoute(
            command: "subscriptions price-points",
            parentParam: "subscription-id",
            parentSegment: "subscriptions",
            segment: "price-points"
        )
    }()
}
