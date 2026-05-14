import Foundation
import Hummingbird
import HummingbirdWebSocket
import ASCPlugin
import Domain
import Infrastructure

/// /api/v1/apps/{appId}/review-submissions — App Store review submissions.
///
/// No top-level `/review-submissions` route: Apple's OpenAPI spec marks
/// `filter[app]` as required, so fleet listing isn't possible without
/// aggregating per-app on the client side.
struct ReviewSubmissionsController: Sendable {
    let submissionRepo: any SubmissionRepository

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
}
