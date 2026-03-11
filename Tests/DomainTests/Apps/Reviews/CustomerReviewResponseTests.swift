import Foundation
import Testing
@testable import Domain

@Suite
struct CustomerReviewResponseTests {

    // MARK: - Parent ID

    @Test func `response carries reviewId`() {
        let response = MockRepositoryFactory.makeCustomerReviewResponse(id: "resp-1", reviewId: "rev-42")
        #expect(response.reviewId == "rev-42")
    }

    // MARK: - State

    @Test func `published state isPublished`() {
        let response = MockRepositoryFactory.makeCustomerReviewResponse(state: .published)
        #expect(response.state.isPublished)
        #expect(!response.state.isPending)
    }

    @Test func `pendingPublish state isPending`() {
        let response = MockRepositoryFactory.makeCustomerReviewResponse(state: .pendingPublish)
        #expect(response.state.isPending)
        #expect(!response.state.isPublished)
    }

    // MARK: - Affordances

    @Test func `response affordances include delete`() {
        let response = MockRepositoryFactory.makeCustomerReviewResponse(id: "resp-1")
        #expect(response.affordances["delete"] == "asc review-responses delete --response-id resp-1")
    }

    @Test func `response affordances include getReview`() {
        let response = MockRepositoryFactory.makeCustomerReviewResponse(id: "resp-1", reviewId: "rev-42")
        #expect(response.affordances["getReview"] == "asc reviews get --review-id rev-42")
    }

    // MARK: - Codable (nil omission)

    @Test func `response omits nil lastModifiedDate from JSON`() throws {
        let response = MockRepositoryFactory.makeCustomerReviewResponse(
            id: "resp-1",
            reviewId: "rev-1",
            responseBody: "Thanks!",
            lastModifiedDate: nil,
            state: .published
        )
        let data = try JSONEncoder().encode(response)
        let json = String(data: data, encoding: .utf8)!
        #expect(!json.contains("lastModifiedDate"))
        #expect(json.contains("responseBody"))
    }
}
