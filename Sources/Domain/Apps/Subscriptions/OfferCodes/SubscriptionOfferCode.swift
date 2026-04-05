public struct SubscriptionOfferCode: Sendable, Equatable, Identifiable {
    public let id: String
    /// Parent subscription identifier — injected by Infrastructure since ASC API omits it from response
    public let subscriptionId: String
    public let name: String
    public let customerEligibilities: [SubscriptionCustomerEligibility]
    public let offerEligibility: SubscriptionOfferEligibility
    public let duration: SubscriptionOfferDuration
    public let offerMode: SubscriptionOfferMode
    public let numberOfPeriods: Int
    public let totalNumberOfCodes: Int?
    public let isActive: Bool

    public init(
        id: String,
        subscriptionId: String,
        name: String,
        customerEligibilities: [SubscriptionCustomerEligibility],
        offerEligibility: SubscriptionOfferEligibility,
        duration: SubscriptionOfferDuration,
        offerMode: SubscriptionOfferMode,
        numberOfPeriods: Int,
        totalNumberOfCodes: Int? = nil,
        isActive: Bool
    ) {
        self.id = id
        self.subscriptionId = subscriptionId
        self.name = name
        self.customerEligibilities = customerEligibilities
        self.offerEligibility = offerEligibility
        self.duration = duration
        self.offerMode = offerMode
        self.numberOfPeriods = numberOfPeriods
        self.totalNumberOfCodes = totalNumberOfCodes
        self.isActive = isActive
    }
}

public enum SubscriptionCustomerEligibility: String, Sendable, Codable, Equatable {
    case new = "NEW"
    case lapsed = "LAPSED"
    case winBack = "WIN_BACK"
    case paidSubscriber = "PAID_SUBSCRIBER"
}

public enum SubscriptionOfferEligibility: String, Sendable, Codable, Equatable {
    case stackable = "STACKABLE"
    case introductory = "INTRODUCTORY"
    case subscriptionOffer = "SUBSCRIPTION_OFFER"
}

extension SubscriptionOfferCode: Codable {
    enum CodingKeys: String, CodingKey {
        case id, subscriptionId, name, customerEligibilities, offerEligibility
        case duration, offerMode, numberOfPeriods, totalNumberOfCodes, isActive
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        subscriptionId = try c.decode(String.self, forKey: .subscriptionId)
        name = try c.decode(String.self, forKey: .name)
        customerEligibilities = try c.decode([SubscriptionCustomerEligibility].self, forKey: .customerEligibilities)
        offerEligibility = try c.decode(SubscriptionOfferEligibility.self, forKey: .offerEligibility)
        duration = try c.decode(SubscriptionOfferDuration.self, forKey: .duration)
        offerMode = try c.decode(SubscriptionOfferMode.self, forKey: .offerMode)
        numberOfPeriods = try c.decode(Int.self, forKey: .numberOfPeriods)
        totalNumberOfCodes = try c.decodeIfPresent(Int.self, forKey: .totalNumberOfCodes)
        isActive = try c.decode(Bool.self, forKey: .isActive)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(subscriptionId, forKey: .subscriptionId)
        try c.encode(name, forKey: .name)
        try c.encode(customerEligibilities, forKey: .customerEligibilities)
        try c.encode(offerEligibility, forKey: .offerEligibility)
        try c.encode(duration, forKey: .duration)
        try c.encode(offerMode, forKey: .offerMode)
        try c.encode(numberOfPeriods, forKey: .numberOfPeriods)
        try c.encodeIfPresent(totalNumberOfCodes, forKey: .totalNumberOfCodes)
        try c.encode(isActive, forKey: .isActive)
    }
}

extension SubscriptionOfferCode: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Name", "Duration", "Mode", "Periods", "Active"]
    }
    public var tableRow: [String] {
        [id, name, duration.rawValue, offerMode.rawValue, String(numberOfPeriods), String(isActive)]
    }
}

extension SubscriptionOfferCode: AffordanceProviding {
    public var affordances: [String: String] {
        var cmds: [String: String] = [
            "listOfferCodes": "asc subscription-offer-codes list --subscription-id \(subscriptionId)",
            "listCustomCodes": "asc subscription-offer-code-custom-codes list --offer-code-id \(id)",
            "listOneTimeCodes": "asc subscription-offer-code-one-time-codes list --offer-code-id \(id)",
        ]
        if isActive {
            cmds["deactivate"] = "asc subscription-offer-codes update --offer-code-id \(id) --active false"
        }
        return cmds
    }
}
