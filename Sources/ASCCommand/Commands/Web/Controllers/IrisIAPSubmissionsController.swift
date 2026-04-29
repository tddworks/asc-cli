import Domain
import Foundation
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// `POST /api/v1/iris/iap/:iapId/submissions` — submits an IAP via the iris private API,
/// the only path that accepts `submitWithNextAppStoreVersion`. Body:
///     { "submitWithNextAppStoreVersion": true }   // default if omitted
///
/// Resolves the iris session via `IrisCookieProvider` (SRP-stored or browser cookies);
/// returns 401-equivalent error if neither is available — surfaced as the standard
/// IrisAPIError stack from the repository.
struct IrisIAPSubmissionsController: Sendable {
    let cookieProvider: any IrisCookieProvider
    let repo: any IrisInAppPurchaseSubmissionRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.post("/iris/iap/:iapId/submissions") { request, context -> Response in
            guard let iapId = context.parameters.get("iapId") else {
                return jsonError("Missing iapId")
            }
            let body = try await request.body.collect(upTo: 64 * 1024)
            let json = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            // Default true: this is what makes the iris path useful (first-time IAP
            // submissions need it). Caller can opt out with `false` for parity-testing
            // against the public SDK shape.
            let withNext = json["submitWithNextAppStoreVersion"] as? Bool ?? true

            let session = try self.cookieProvider.resolveSession()
            let submission = try await self.repo.submitInAppPurchase(
                session: session,
                iapId: iapId,
                submitWithNextAppStoreVersion: withNext
            )
            return try restFormat(submission)
        }

        // Matches the `removeFromNextVersion` affordance's `_links` URL. Iris-queued
        // submissions can only be removed via the iris DELETE; the submission resource
        // is keyed by parent IAP id, so the path param IS the submission id.
        group.delete("/iris/iap-submissions/:submissionId") { _, context -> Response in
            guard let submissionId = context.parameters.get("submissionId") else {
                return jsonError("Missing submissionId")
            }
            let session = try self.cookieProvider.resolveSession()
            try await self.repo.deleteSubmission(session: session, submissionId: submissionId)
            return restResponse("{\"deleted\":true}")
        }
    }
}
