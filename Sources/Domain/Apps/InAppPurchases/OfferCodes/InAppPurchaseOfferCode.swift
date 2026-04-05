public struct InAppPurchaseOfferCode: Sendable, Equatable, Identifiable {
    public let id: String
    /// Parent IAP identifier — injected by Infrastructure since ASC API omits it from response
    public let iapId: String
    public let name: String
    public let customerEligibilities: [IAPCustomerEligibility]
    public let isActive: Bool
    public let totalNumberOfCodes: Int?

    public init(
        id: String,
        iapId: String,
        name: String,
        customerEligibilities: [IAPCustomerEligibility],
        isActive: Bool,
        totalNumberOfCodes: Int? = nil
    ) {
        self.id = id
        self.iapId = iapId
        self.name = name
        self.customerEligibilities = customerEligibilities
        self.isActive = isActive
        self.totalNumberOfCodes = totalNumberOfCodes
    }
}

public enum IAPCustomerEligibility: String, Sendable, Codable, Equatable {
    case nonSpender = "NON_SPENDER"
    case activeSpender = "ACTIVE_SPENDER"
    case churnedSpender = "CHURNED_SPENDER"
}

extension InAppPurchaseOfferCode: Codable {
    enum CodingKeys: String, CodingKey {
        case id, iapId, name, customerEligibilities, isActive, totalNumberOfCodes
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        iapId = try c.decode(String.self, forKey: .iapId)
        name = try c.decode(String.self, forKey: .name)
        customerEligibilities = try c.decode([IAPCustomerEligibility].self, forKey: .customerEligibilities)
        isActive = try c.decode(Bool.self, forKey: .isActive)
        totalNumberOfCodes = try c.decodeIfPresent(Int.self, forKey: .totalNumberOfCodes)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(iapId, forKey: .iapId)
        try c.encode(name, forKey: .name)
        try c.encode(customerEligibilities, forKey: .customerEligibilities)
        try c.encode(isActive, forKey: .isActive)
        try c.encodeIfPresent(totalNumberOfCodes, forKey: .totalNumberOfCodes)
    }
}

extension InAppPurchaseOfferCode: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Name", "Eligibilities", "Active"]
    }
    public var tableRow: [String] {
        [id, name, customerEligibilities.map(\.rawValue).joined(separator: ", "), String(isActive)]
    }
}

extension InAppPurchaseOfferCode: AffordanceProviding {
    public var affordances: [String: String] {
        var cmds: [String: String] = [
            "listOfferCodes": "asc iap-offer-codes list --iap-id \(iapId)",
            "listCustomCodes": "asc iap-offer-code-custom-codes list --offer-code-id \(id)",
            "listOneTimeCodes": "asc iap-offer-code-one-time-codes list --offer-code-id \(id)",
        ]
        if isActive {
            cmds["deactivate"] = "asc iap-offer-codes update --offer-code-id \(id) --active false"
        }
        return cmds
    }
}
