public struct SubscriptionOfferCodeOneTimeUseCode: Sendable, Equatable, Identifiable {
    public let id: String
    /// Parent offer code identifier — injected by Infrastructure
    public let offerCodeId: String
    public let numberOfCodes: Int
    public let createdDate: String?
    public let expirationDate: String?
    public let isActive: Bool

    public init(
        id: String,
        offerCodeId: String,
        numberOfCodes: Int,
        createdDate: String? = nil,
        expirationDate: String? = nil,
        isActive: Bool
    ) {
        self.id = id
        self.offerCodeId = offerCodeId
        self.numberOfCodes = numberOfCodes
        self.createdDate = createdDate
        self.expirationDate = expirationDate
        self.isActive = isActive
    }
}

extension SubscriptionOfferCodeOneTimeUseCode: Codable {
    enum CodingKeys: String, CodingKey {
        case id, offerCodeId, numberOfCodes, createdDate, expirationDate, isActive
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        offerCodeId = try c.decode(String.self, forKey: .offerCodeId)
        numberOfCodes = try c.decode(Int.self, forKey: .numberOfCodes)
        createdDate = try c.decodeIfPresent(String.self, forKey: .createdDate)
        expirationDate = try c.decodeIfPresent(String.self, forKey: .expirationDate)
        isActive = try c.decode(Bool.self, forKey: .isActive)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(offerCodeId, forKey: .offerCodeId)
        try c.encode(numberOfCodes, forKey: .numberOfCodes)
        try c.encodeIfPresent(createdDate, forKey: .createdDate)
        try c.encodeIfPresent(expirationDate, forKey: .expirationDate)
        try c.encode(isActive, forKey: .isActive)
    }
}

extension SubscriptionOfferCodeOneTimeUseCode: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Codes", "Expiration", "Active"]
    }
    public var tableRow: [String] {
        [id, String(numberOfCodes), expirationDate ?? "", String(isActive)]
    }
}

extension SubscriptionOfferCodeOneTimeUseCode: AffordanceProviding {
    public var affordances: [String: String] {
        var cmds: [String: String] = [
            "listOneTimeCodes": "asc subscription-offer-code-one-time-codes list --offer-code-id \(offerCodeId)",
        ]
        if isActive {
            cmds["deactivate"] = "asc subscription-offer-code-one-time-codes update --one-time-code-id \(id) --active false"
        }
        return cmds
    }
}
