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
    }
}
