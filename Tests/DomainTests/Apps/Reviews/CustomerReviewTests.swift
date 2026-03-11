import Foundation
import Testing
@testable import Domain

@Suite
struct CustomerReviewTests {

    // MARK: - Parent ID

    @Test func `review carries appId`() {
        let review = MockRepositoryFactory.makeCustomerReview(id: "rev-1", appId: "app-42")
        #expect(review.appId == "app-42")
    }

    // MARK: - Fields

    @Test func `review carries rating and text fields`() {
        let review = MockRepositoryFactory.makeCustomerReview(
            id: "rev-1",
            rating: 5,
            title: "Great app!",
            body: "Love it",
            reviewerNickname: "user123"
        )
        #expect(review.rating == 5)
        #expect(review.title == "Great app!")
        #expect(review.body == "Love it")
        #expect(review.reviewerNickname == "user123")
    }

    @Test func `review territory is optional`() {
        let review = MockRepositoryFactory.makeCustomerReview(territory: "USA")
        #expect(review.territory == "USA")

        let noTerritory = MockRepositoryFactory.makeCustomerReview(territory: nil)
        #expect(noTerritory.territory == nil)
    }

    // MARK: - Affordances

    @Test func `review affordances include getResponse`() {
        let review = MockRepositoryFactory.makeCustomerReview(id: "rev-1")
        #expect(review.affordances["getResponse"] == "asc review-responses get --review-id rev-1")
    }

    @Test func `review affordances include respond`() {
        let review = MockRepositoryFactory.makeCustomerReview(id: "rev-1")
        #expect(review.affordances["respond"] == "asc review-responses create --review-id rev-1 --response-body \"\"")
    }

    @Test func `review affordances include listReviews`() {
        let review = MockRepositoryFactory.makeCustomerReview(id: "rev-1", appId: "app-42")
        #expect(review.affordances["listReviews"] == "asc reviews list --app-id app-42")
    }

    // MARK: - Codable (nil omission)

    @Test func `review omits nil fields from JSON`() throws {
        let review = MockRepositoryFactory.makeCustomerReview(
            id: "rev-1",
            appId: "app-1",
            rating: 5,
            title: nil,
            body: nil,
            reviewerNickname: nil,
            createdDate: nil,
            territory: nil
        )
        let data = try JSONEncoder().encode(review)
        let json = String(data: data, encoding: .utf8)!
        #expect(!json.contains("title"))
        #expect(!json.contains("body"))
        #expect(!json.contains("reviewerNickname"))
        #expect(!json.contains("createdDate"))
        #expect(!json.contains("territory"))
    }
}