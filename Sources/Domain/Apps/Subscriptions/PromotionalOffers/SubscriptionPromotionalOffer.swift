public struct SubscriptionPromotionalOffer: Sendable, Equatable, Identifiable {
    public let id: String
    /// Parent subscription identifier — injected by Infrastructure
    public let subscriptionId: String
    public let name: String
    public let offerCode: String
    public let duration: SubscriptionOfferDuration
    public let offerMode: SubscriptionOfferMode
    public let numberOfPeriods: Int

    public init(
        id: String,
        subscriptionId: String,
        name: String,
        offerCode: String,
        duration: SubscriptionOfferDuration,
        offerMode: SubscriptionOfferMode,
        numberOfPeriods: Int
    ) {
        self.id = id
        self.subscriptionId = subscriptionId
        self.name = name
        self.offerCode = offerCode
        self.duration = duration
        self.offerMode = offerMode
        self.numberOfPeriods = numberOfPeriods
    }
}

extension SubscriptionPromotionalOffer: Codable {
    enum CodingKeys: String, CodingKey {
        case id, subscriptionId, name, offerCode, duration, offerMode, numberOfPeriods
    }
}

extension SubscriptionPromotionalOffer: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Name", "Offer Code", "Duration", "Mode", "Periods"]
    }
    public var tableRow: [String] {
        [id, name, offerCode, duration.rawValue, offerMode.rawValue, String(numberOfPeriods)]
    }
}

extension SubscriptionPromotionalOffer: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "delete": "asc subscription-promotional-offers delete --offer-id \(id)",
            "listOffers": "asc subscription-promotional-offers list --subscription-id \(subscriptionId)",
            "listPrices": "asc subscription-promotional-offers prices list --offer-id \(id)",
        ]
    }
}
