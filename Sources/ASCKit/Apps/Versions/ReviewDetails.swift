import Mockable

@Mockable
public protocol ReviewDetails: Sendable {
    func getReviewDetail(versionId: String) async throws -> AppStoreReviewDetail
    func upsertReviewDetail(versionId: String, update: ReviewDetailUpdate) async throws -> AppStoreReviewDetail
}
