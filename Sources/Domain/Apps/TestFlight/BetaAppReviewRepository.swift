import Mockable

@Mockable
public protocol BetaAppReviewRepository: Sendable {
    func listSubmissions(buildId: String) async throws -> [BetaAppReviewSubmission]
    func createSubmission(buildId: String) async throws -> BetaAppReviewSubmission
    func getSubmission(id: String) async throws -> BetaAppReviewSubmission
    func getDetail(appId: String) async throws -> BetaAppReviewDetail
    func updateDetail(id: String, update: BetaAppReviewDetailUpdate) async throws -> BetaAppReviewDetail
}
