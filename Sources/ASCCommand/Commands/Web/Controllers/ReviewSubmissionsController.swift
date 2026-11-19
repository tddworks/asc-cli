import Foundation
import Hummingbird
import HummingbirdWebSocket
import ASCPlugin
import ASCKit

/// /api/v1/apps/{appId}/review-submissions — App Store review submissions.
///
/// No top-level `/review-submissions` route: Apple's OpenAPI spec marks
/// `filter[app]` as required, so fleet listing isn't possible without
/// aggregating per-app on the client side.
struct ReviewSubmissionsController: Sendable {
    let submissionRepo: any ReviewSubmissions

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/apps/:appId/review-submissions") { request, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }

            let query = request.uri.queryParameters
            let states: [ReviewSubmissionState]? = query["state"].map { csv in
                csv.split(separator: ",").compactMap {
                    ReviewSubmissionState(rawValue: String($0).trimmingCharacters(in: .whitespaces).uppercased())
                }
            }
            let limit = query["limit"].flatMap { Int($0) }

            let items = try await self.submissionRepo.listSubmissions(appId: appId, states: states, limit: limit)
            return try restFormat(items)
        }

        // POST /api/v1/apps/:appId/review-submissions {"platform": "ios"} — open (or reuse) a draft.
        group.post("/apps/:appId/review-submissions") { request, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let json = try await Self.jsonBody(request)
            let platformRaw = (json["platform"] as? String) ?? "ios"
            guard let platform = AppStorePlatform(cliArgument: platformRaw) ?? AppStorePlatform(rawValue: platformRaw) else {
                return jsonError("Invalid platform '\(platformRaw)'", status: .badRequest)
            }
            return try restFormat(try await self.submissionRepo.createSubmission(appId: appId, platform: platform))
        }

        // POST /api/v1/review-submissions/:id/items — body carries exactly one of the CLI's
        // version flags as a key: version-id, iap-version-id, subscription-version-id,
        // subscription-group-version-id.
        group.post("/review-submissions/:id/items") { request, context -> Response in
            guard let id = context.parameters.get("id") else { return jsonError("Missing submission id") }
            let json = try await Self.jsonBody(request)
            guard let target = ReviewItemTarget(
                versionId: json["version-id"] as? String,
                iapVersionId: json["iap-version-id"] as? String,
                subscriptionVersionId: json["subscription-version-id"] as? String,
                subscriptionGroupVersionId: json["subscription-group-version-id"] as? String
            ) else {
                return jsonError(
                    "Body needs exactly one of version-id, iap-version-id, subscription-version-id, subscription-group-version-id",
                    status: .badRequest
                )
            }
            return try restFormat(try await self.submissionRepo.addItem(submissionId: id, target: target))
        }

        // DELETE /api/v1/review-submissions/items/:itemId — remove an item from a draft.
        group.delete("/review-submissions/items/:itemId") { _, context -> Response in
            guard let itemId = context.parameters.get("itemId") else { return jsonError("Missing item id") }
            try await self.submissionRepo.removeItem(itemId: itemId)
            return restResponse("{\"removed\":true}")
        }

        // POST /api/v1/review-submissions/:id/submit — send the draft to App Review.
        group.post("/review-submissions/:id/submit") { _, context -> Response in
            guard let id = context.parameters.get("id") else { return jsonError("Missing submission id") }
            return try restFormat(try await self.submissionRepo.submit(submissionId: id))
        }

        // GET /api/v1/review-submissions/:id — single submission detail.
        group.get("/review-submissions/:id") { _, context -> Response in
            guard let id = context.parameters.get("id") else { return jsonError("Missing submission id") }
            let submission = try await self.submissionRepo.getSubmission(id: id)
            return try restFormat(submission)
        }

        // GET /api/v1/review-submissions/:id/items — list items; ?state= filters them.
        // The `?state=` query param mirrors the CLI's `--state` flag.
        group.get("/review-submissions/:id/items") { request, context -> Response in
            guard let id = context.parameters.get("id") else { return jsonError("Missing submission id") }
            var items = try await self.submissionRepo.listSubmissionItems(submissionId: id)
            if let raw = request.uri.queryParameters["state"],
               let filter = ReviewSubmissionItemState(rawValue: String(raw).uppercased()) {
                items = items.filter { $0.state == filter }
            }
            return try restFormat(items)
        }
    }

    private static func jsonBody(_ request: Request) async throws -> [String: Any] {
        let body = try await request.body.collect(upTo: 64 * 1024)
        return (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
    }
}
