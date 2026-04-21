import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return `CustomerReview` resources.
struct CustomerReviewsController: Sendable {
    let repo: any CustomerReviewRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/apps/:appId/reviews") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let reviews = try await self.repo.listReviews(appId: appId)
            return try restFormat(reviews)
        }
    }
}
