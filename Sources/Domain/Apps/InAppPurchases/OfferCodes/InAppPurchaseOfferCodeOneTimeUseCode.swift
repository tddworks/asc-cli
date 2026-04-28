public struct InAppPurchaseOfferCodeOneTimeUseCode: Sendable, Equatable, Identifiable {
    public let id: String
    /// Parent offer code identifier — injected by Infrastructure
    public let offerCodeId: String
    public let numberOfCodes: Int
    public let createdDate: String?
    public let expirationDate: String?
    public let isActive: Bool
    /// PRODUCTION or SANDBOX. Sandbox batches redeem against sandbox tester accounts and
    /// have a smaller per-quarter ceiling — iOS clients filter by this to render production
    /// and sandbox batch lists separately.
    public let environment: OfferCodeEnvironment?

    public init(
        id: String,
        offerCodeId: String,
        numberOfCodes: Int,
        createdDate: String? = nil,
        expirationDate: String? = nil,
        isActive: Bool,
        environment: OfferCodeEnvironment? = nil
    ) {
        self.id = id
        self.offerCodeId = offerCodeId
        self.numberOfCodes = numberOfCodes
        self.createdDate = createdDate
        self.expirationDate = expirationDate
        self.isActive = isActive
        self.environment = environment
    }
}

extension InAppPurchaseOfferCodeOneTimeUseCode: Codable {
    enum CodingKeys: String, CodingKey {
        case id, offerCodeId, numberOfCodes, createdDate, expirationDate, isActive, environment
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        offerCodeId = try c.decode(String.self, forKey: .offerCodeId)
        numberOfCodes = try c.decode(Int.self, forKey: .numberOfCodes)
        createdDate = try c.decodeIfPresent(String.self, forKey: .createdDate)
        expirationDate = try c.decodeIfPresent(String.self, forKey: .expirationDate)
        isActive = try c.decode(Bool.self, forKey: .isActive)
        environment = try c.decodeIfPresent(OfferCodeEnvironment.self, forKey: .environment)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(offerCodeId, forKey: .offerCodeId)
        try c.encode(numberOfCodes, forKey: .numberOfCodes)
        try c.encodeIfPresent(createdDate, forKey: .createdDate)
        try c.encodeIfPresent(expirationDate, forKey: .expirationDate)
        try c.encode(isActive, forKey: .isActive)
        try c.encodeIfPresent(environment, forKey: .environment)
    }
}

extension InAppPurchaseOfferCodeOneTimeUseCode: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Codes", "Expiration", "Active", "Env"]
    }
    public var tableRow: [String] {
        [id, String(numberOfCodes), expirationDate ?? "", String(isActive), environment?.rawValue ?? ""]
    }
}

extension InAppPurchaseOfferCodeOneTimeUseCode: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        var items: [Affordance] = [
            Affordance(key: "listOneTimeCodes", command: "iap-offer-code-one-time-codes", action: "list", params: ["offer-code-id": offerCodeId]),
        ]
        if isActive {
            items.append(Affordance(key: "deactivate", command: "iap-offer-code-one-time-codes", action: "update", params: ["one-time-code-id": id, "active": "false"]))
        }
        return items
    }
}
