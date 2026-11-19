public struct Territory: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let currency: String?

    public init(id: String, currency: String?) {
        self.id = id
        self.currency = currency
    }

    enum CodingKeys: String, CodingKey {
        case id, currency
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        currency = try c.decodeIfPresent(String.self, forKey: .currency)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encodeIfPresent(currency, forKey: .currency)
    }
}

extension Territory: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Currency"]
    }
    public var tableRow: [String] {
        [id, currency ?? "—"]
    }
}

extension Territory: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "listTerritories": "asc territories list",
        ]
    }
}
