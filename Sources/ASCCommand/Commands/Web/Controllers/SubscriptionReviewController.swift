import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return the subscription review screenshot and promotional images.
struct SubscriptionReviewController: Sendable {
    let repo: any SubscriptionReviewRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/subscriptions/:subscriptionId/review-screenshot") { _, context -> Response in
            guard let subscriptionId = context.parameters.get("subscriptionId") else { return jsonError("Missing subscriptionId") }
            let item = try await self.repo.getReviewScreenshot(subscriptionId: subscriptionId)
            return try restFormat(item.map { [$0] } ?? [])
        }

        group.get("/subscriptions/:subscriptionId/images") { _, context -> Response in
            guard let subscriptionId = context.parameters.get("subscriptionId") else { return jsonError("Missing subscriptionId") }
            let items = try await self.repo.listImages(subscriptionId: subscriptionId)
            return try restFormat(items)
        }
    }
}
