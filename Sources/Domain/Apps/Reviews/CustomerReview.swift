import Foundation

public struct CustomerReview: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let appId: String
    public let rating: Int
    public let title: String?
    public let body: String?
    public let reviewerNickname: String?
    public let createdDate: Date?
    public let territory: String?

    public init(
        id: String,
        appId: String,
        rating: Int,
        title: String? = nil,
        body: String? = nil,
        reviewerNickname: String? = nil,
        createdDate: Date? = nil,
        territory: String? = nil
    ) {
        self.id = id
        self.appId = appId
        self.rating = rating
        self.title = title
        self.body = body
        self.reviewerNickname = reviewerNickname
        self.createdDate = createdDate
        self.territory = territory
    }

    // MARK: - Custom Codable (omit nil)

    enum CodingKeys: String, CodingKey {
        case id, appId, rating, title, body, reviewerNickname, createdDate, territory
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(appId, forKey: .appId)
        try container.encode(rating, forKey: .rating)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(body, forKey: .body)
        try container.encodeIfPresent(reviewerNickname, forKey: .reviewerNickname)
        try container.encodeIfPresent(createdDate, forKey: .createdDate)
        try container.encodeIfPresent(territory, forKey: .territory)
    }
}

extension CustomerReview: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "getResponse": "asc review-responses get --review-id \(id)",
            "respond": "asc review-responses create --review-id \(id) --response-body \"\"",
            "listReviews": "asc reviews list --app-id \(appId)",
        ]
    }
}
