import Foundation

public enum ReviewResponseState: String, Sendable, Equatable, Codable {
    case published = "PUBLISHED"
    case pendingPublish = "PENDING_PUBLISH"

    public var isPublished: Bool { self == .published }
    public var isPending: Bool { self == .pendingPublish }
}

public struct CustomerReviewResponse: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let reviewId: String
    public let responseBody: String
    public let lastModifiedDate: Date?
    public let state: ReviewResponseState

    public init(
        id: String,
        reviewId: String,
        responseBody: String,
        lastModifiedDate: Date? = nil,
        state: ReviewResponseState = .published
    ) {
        self.id = id
        self.reviewId = reviewId
        self.responseBody = responseBody
        self.lastModifiedDate = lastModifiedDate
        self.state = state
    }

    // MARK: - Custom Codable (omit nil)

    enum CodingKeys: String, CodingKey {
        case id, reviewId, responseBody, lastModifiedDate, state
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(reviewId, forKey: .reviewId)
        try container.encode(responseBody, forKey: .responseBody)
        try container.encodeIfPresent(lastModifiedDate, forKey: .lastModifiedDate)
        try container.encode(state, forKey: .state)
    }
}

extension CustomerReviewResponse: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "delete": "asc review-responses delete --response-id \(id)",
            "getReview": "asc reviews get --review-id \(reviewId)",
        ]
    }
}
