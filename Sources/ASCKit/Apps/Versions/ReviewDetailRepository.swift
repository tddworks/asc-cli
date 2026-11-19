import Mockable

@Mockable
public protocol ReviewDetailRepository: Sendable {
    func getReviewDetail(versionId: String) async throws -> AppStoreReviewDetail
    func upsertReviewDetail(versionId: String, update: ReviewDetailUpdate) async throws -> AppStoreReviewDetail
}
