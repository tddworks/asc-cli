import Mockable

@Mockable
public protocol SubscriptionSubmissions: Sendable {
    func submitSubscription(subscriptionId: String) async throws -> SubscriptionSubmission
    func deleteSubmission(submissionId: String) async throws
}
