import Domain
import Foundation
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// `GET /api/v1/iris/review-submissions/:submissionId/resolution-center` —
/// App Review's Resolution Center messages and rejection reasons for a review
/// submission. Iris private API only (browser-cookie auth); the official App
/// Store Connect API has no endpoint for this data.
///
/// `?plain-text=true` mirrors the CLI's `--plain-text` flag (HTML → text).
struct IrisResolutionCenterController: Sendable {
    let cookieProvider: any IrisCookieProvider
    let repo: any IrisResolutionCenterRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/iris/review-submissions/:submissionId/resolution-center") { request, context -> Response in
            guard let submissionId = context.parameters.get("submissionId") else {
                return jsonError("Missing submissionId")
            }
            let session = try self.cookieProvider.resolveSession()
            var detail = try await self.repo.getResolution(session: session, submissionId: submissionId)
            if request.uri.queryParameters["plain-text"] == "true" {
                detail = detail.plainText()
            }
            return try restFormat(detail)
        }
    }
}
