public struct SubscriptionOfferCodeCustomCode: Sendable, Equatable, Identifiable {
    public let id: String
    /// Parent offer code identifier — injected by Infrastructure
    public let offerCodeId: String
    public let customCode: String
    public let numberOfCodes: Int
    public let createdDate: String?
    public let expirationDate: String?
    public let isActive: Bool

    public init(
        id: String,
        offerCodeId: String,
        customCode: String,
        numberOfCodes: Int,
        createdDate: String? = nil,
        expirationDate: String? = nil,
        isActive: Bool
    ) {
        self.id = id
        self.offerCodeId = offerCodeId
        self.customCode = customCode
        self.numberOfCodes = numberOfCodes
        self.createdDate = createdDate
        self.expirationDate = expirationDate
        self.isActive = isActive
    }
}

extension SubscriptionOfferCodeCustomCode: Codable {
    enum CodingKeys: String, CodingKey {
        case id, offerCodeId, customCode, numberOfCodes, createdDate, expirationDate, isActive
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        offerCodeId = try c.decode(String.self, forKey: .offerCodeId)
        customCode = try c.decode(String.self, forKey: .customCode)
        numberOfCodes = try c.decode(Int.self, forKey: .numberOfCodes)
        createdDate = try c.decodeIfPresent(String.self, forKey: .createdDate)
        expirationDate = try c.decodeIfPresent(String.self, forKey: .expirationDate)
        isActive = try c.decode(Bool.self, forKey: .isActive)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(offerCodeId, forKey: .offerCodeId)
        try c.encode(customCode, forKey: .customCode)
        try c.encode(numberOfCodes, forKey: .numberOfCodes)
        try c.encodeIfPresent(createdDate, forKey: .createdDate)
        try c.encodeIfPresent(expirationDate, forKey: .expirationDate)
        try c.encode(isActive, forKey: .isActive)
    }
}

extension SubscriptionOfferCodeCustomCode: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Custom Code", "Codes", "Expiration", "Active"]
    }
    public var tableRow: [String] {
        [id, customCode, String(numberOfCodes), expirationDate ?? "", String(isActive)]
    }
}

extension SubscriptionOfferCodeCustomCode: AffordanceProviding {
    public var affordances: [String: String] {
        var cmds: [String: String] = [
            "listCustomCodes": "asc subscription-offer-code-custom-codes list --offer-code-id \(offerCodeId)",
        ]
        if isActive {
            cmds["deactivate"] = "asc subscription-offer-code-custom-codes update --custom-code-id \(id) --active false"
        }
        return cmds
    }
}
