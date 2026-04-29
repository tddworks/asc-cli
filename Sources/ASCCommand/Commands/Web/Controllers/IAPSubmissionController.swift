import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// `POST /iap/:iapId/submit` — submits an IAP for App Store review.
/// `DELETE /iap-submissions/:submissionId` — unsubmits (withdraws from review).
///
/// Apple constraint: the *first* IAP for an app must be submitted alongside a new
/// app version; the API returns an error otherwise. Subsequent submits are standalone.
/// We surface ASC's error verbatim — no client-side gating yet (see readiness-checklist
/// design note in CHANGELOG).
struct IAPSubmissionController: Sendable {
    let repo: any InAppPurchaseSubmissionRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.post("/iap/:iapId/submit") { _, context -> Response in
            guard let iapId = context.parameters.get("iapId") else { return jsonError("Missing iapId") }
            let submission = try await self.repo.submitInAppPurchase(iapId: iapId)
            return try restFormat(submission)
        }

        group.delete("/iap-submissions/:submissionId") { _, context -> Response in
            guard let submissionId = context.parameters.get("submissionId") else { return jsonError("Missing submissionId") }
            try await self.repo.deleteSubmission(submissionId: submissionId)
            return restResponse("{\"deleted\":true}")
        }
    }
}
