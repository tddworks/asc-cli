public struct InAppPurchasePricePoint: Sendable, Equatable, Identifiable {
    public let id: String
    /// Parent IAP identifier — injected by Infrastructure
    public let iapId: String
    public let territory: String?
    public let customerPrice: String?
    public let proceeds: String?

    public init(
        id: String,
        iapId: String,
        territory: String? = nil,
        customerPrice: String? = nil,
        proceeds: String? = nil
    ) {
        self.id = id
        self.iapId = iapId
        self.territory = territory
        self.customerPrice = customerPrice
        self.proceeds = proceeds
    }
}

extension InAppPurchasePricePoint: Codable {
    enum CodingKeys: String, CodingKey {
        case id, iapId, territory, customerPrice, proceeds
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        iapId = try c.decode(String.self, forKey: .iapId)
        territory = try c.decodeIfPresent(String.self, forKey: .territory)
        customerPrice = try c.decodeIfPresent(String.self, forKey: .customerPrice)
        proceeds = try c.decodeIfPresent(String.self, forKey: .proceeds)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(iapId, forKey: .iapId)
        try c.encodeIfPresent(territory, forKey: .territory)
        try c.encodeIfPresent(customerPrice, forKey: .customerPrice)
        try c.encodeIfPresent(proceeds, forKey: .proceeds)
    }
}

extension InAppPurchasePricePoint: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Territory", "Customer Price", "Proceeds"]
    }
    public var tableRow: [String] {
        [id, territory ?? "", customerPrice ?? "", proceeds ?? ""]
    }
}

extension InAppPurchasePricePoint: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        var items: [Affordance] = [
            Affordance(key: "listPricePoints", command: "iap price-points", action: "list", params: ["iap-id": iapId]),
        ]
        if let territory {
            items.append(Affordance(key: "setPrice", command: "iap prices", action: "set",
                                    params: ["iap-id": iapId, "base-territory": territory, "price-point-id": id]))
        }
        return items
    }
}
