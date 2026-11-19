import Mockable

@Mockable
public protocol InAppPurchaseSubmissionRepository: Sendable {
    func submitInAppPurchase(iapId: String) async throws -> InAppPurchaseSubmission
    func deleteSubmission(submissionId: String) async throws
}
