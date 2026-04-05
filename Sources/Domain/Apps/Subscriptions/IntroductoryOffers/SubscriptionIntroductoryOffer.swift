public struct SubscriptionIntroductoryOffer: Sendable, Equatable, Identifiable {
    public let id: String
    /// Parent subscription identifier — injected by Infrastructure since ASC API omits it from response
    public let subscriptionId: String
    public let duration: SubscriptionOfferDuration
    public let offerMode: SubscriptionOfferMode
    public let numberOfPeriods: Int
    public let startDate: String?
    public let endDate: String?
    public let territory: String?

    public init(
        id: String,
        subscriptionId: String,
        duration: SubscriptionOfferDuration,
        offerMode: SubscriptionOfferMode,
        numberOfPeriods: Int,
        startDate: String? = nil,
        endDate: String? = nil,
        territory: String? = nil
    ) {
        self.id = id
        self.subscriptionId = subscriptionId
        self.duration = duration
        self.offerMode = offerMode
        self.numberOfPeriods = numberOfPeriods
        self.startDate = startDate
        self.endDate = endDate
        self.territory = territory
    }
}

public enum SubscriptionOfferDuration: String, Sendable, Codable, Equatable {
    case threeDays = "THREE_DAYS"
    case oneWeek = "ONE_WEEK"
    case twoWeeks = "TWO_WEEKS"
    case oneMonth = "ONE_MONTH"
    case twoMonths = "TWO_MONTHS"
    case threeMonths = "THREE_MONTHS"
    case sixMonths = "SIX_MONTHS"
    case oneYear = "ONE_YEAR"
}

public enum SubscriptionOfferMode: String, Sendable, Codable, Equatable {
    case payAsYouGo = "PAY_AS_YOU_GO"
    case payUpFront = "PAY_UP_FRONT"
    case freeTrial = "FREE_TRIAL"

    public var requiresPricePoint: Bool { self == .payAsYouGo || self == .payUpFront }
}

extension SubscriptionIntroductoryOffer: Codable {
    enum CodingKeys: String, CodingKey {
        case id, subscriptionId, duration, offerMode, numberOfPeriods, startDate, endDate, territory
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        subscriptionId = try c.decode(String.self, forKey: .subscriptionId)
        duration = try c.decode(SubscriptionOfferDuration.self, forKey: .duration)
        offerMode = try c.decode(SubscriptionOfferMode.self, forKey: .offerMode)
        numberOfPeriods = try c.decode(Int.self, forKey: .numberOfPeriods)
        startDate = try c.decodeIfPresent(String.self, forKey: .startDate)
        endDate = try c.decodeIfPresent(String.self, forKey: .endDate)
        territory = try c.decodeIfPresent(String.self, forKey: .territory)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(subscriptionId, forKey: .subscriptionId)
        try c.encode(duration, forKey: .duration)
        try c.encode(offerMode, forKey: .offerMode)
        try c.encode(numberOfPeriods, forKey: .numberOfPeriods)
        try c.encodeIfPresent(startDate, forKey: .startDate)
        try c.encodeIfPresent(endDate, forKey: .endDate)
        try c.encodeIfPresent(territory, forKey: .territory)
    }
}

extension SubscriptionIntroductoryOffer: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Duration", "Mode", "Periods", "Territory"]
    }
    public var tableRow: [String] {
        [id, duration.rawValue, offerMode.rawValue, String(numberOfPeriods), territory ?? ""]
    }
}

extension SubscriptionIntroductoryOffer: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "listOffers": "asc subscription-offers list --subscription-id \(subscriptionId)",
        ]
    }
}
