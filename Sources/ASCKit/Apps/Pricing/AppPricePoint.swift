/// One price an app can be sold at in a territory (Apple's fixed price tiers).
/// Setting the app's price means picking one of these as the base-territory price;
/// Apple equalizes the other territories from it.
public struct AppPricePoint: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    /// Parent app — Apple's response omits it, so Infrastructure injects it.
    public let appId: String
    public let territory: String?
    public let customerPrice: String?
    public let proceeds: String?

    public init(id: String, appId: String, territory: String?, customerPrice: String?, proceeds: String?) {
        self.id = id
        self.appId = appId
        self.territory = territory
        self.customerPrice = customerPrice
        self.proceeds = proceeds
    }

    /// The zero price point — choosing it makes the app free.
    public var isFree: Bool { customerPrice.flatMap(Double.init) == 0 }
}

extension AppPricePoint {
    enum CodingKeys: String, CodingKey {
        case id, appId, territory, customerPrice, proceeds
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        appId = try c.decode(String.self, forKey: .appId)
        territory = try c.decodeIfPresent(String.self, forKey: .territory)
        customerPrice = try c.decodeIfPresent(String.self, forKey: .customerPrice)
        proceeds = try c.decodeIfPresent(String.self, forKey: .proceeds)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(appId, forKey: .appId)
        try c.encodeIfPresent(territory, forKey: .territory)
        try c.encodeIfPresent(customerPrice, forKey: .customerPrice)
        try c.encodeIfPresent(proceeds, forKey: .proceeds)
    }
}

extension AppPricePoint: Presentable {
    public static var tableHeaders: [String] { ["ID", "Territory", "Customer Price", "Proceeds"] }
    public var tableRow: [String] { [id, territory ?? "", customerPrice ?? "", proceeds ?? ""] }
}

extension AppPricePoint: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        guard let territory else { return [] }
        return [
            Affordance(key: "listPricePoints", command: "apps price-points", action: "list",
                       params: ["app-id": appId, "territory": territory]),
            Affordance(key: "setPrice", command: "apps prices", action: "set",
                       params: ["app-id": appId, "base-territory": territory, "price-point-id": id]),
        ]
    }
}
