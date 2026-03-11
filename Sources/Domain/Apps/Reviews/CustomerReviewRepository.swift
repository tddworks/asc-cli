import Mockable

@Mockable
public protocol CustomerReviewRepository: Sendable {
    func listReviews(appId: String) async throws -> [CustomerReview]
    func getReview(reviewId: String) async throws -> CustomerReview
    func getResponse(reviewId: String) async throws -> CustomerReviewResponse
    func createResponse(reviewId: String, responseBody: String) async throws -> CustomerReviewResponse
    func deleteResponse(responseId: String) async throws
}
