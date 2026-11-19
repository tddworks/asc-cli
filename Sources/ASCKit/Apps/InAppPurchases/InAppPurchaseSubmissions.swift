import Mockable

@Mockable
public protocol InAppPurchaseSubmissions: Sendable {
    func submitInAppPurchase(iapId: String) async throws -> InAppPurchaseSubmission
    func deleteSubmission(submissionId: String) async throws
}
