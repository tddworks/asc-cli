import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// `POST /subscriptions/:subscriptionId/submit` — submits a subscription for review.
/// `DELETE /subscription-submissions/:submissionId` — unsubmits.
///
/// Apple constraint: the first subscription within a group must be submitted with a
/// new app version; subsequent submissions are standalone. ASC enforces this.
struct SubscriptionSubmissionController: Sendable {
    let repo: any SubscriptionSubmissionRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.post("/subscriptions/:subscriptionId/submit") { _, context -> Response in
            guard let subscriptionId = context.parameters.get("subscriptionId") else { return jsonError("Missing subscriptionId") }
            let submission = try await self.repo.submitSubscription(subscriptionId: subscriptionId)
            return try restFormat(submission)
        }

        group.delete("/subscription-submissions/:submissionId") { _, context -> Response in
            guard let submissionId = context.parameters.get("submissionId") else { return jsonError("Missing submissionId") }
            try await self.repo.deleteSubmission(submissionId: submissionId)
            return restResponse("{\"deleted\":true}")
        }
    }
}
