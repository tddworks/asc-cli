import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return the per-territory availability of a subscription.
struct SubscriptionAvailabilityController: Sendable {
    let repo: any SubscriptionAvailabilityRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/subscriptions/:subscriptionId/availability") { _, context -> Response in
            guard let subscriptionId = context.parameters.get("subscriptionId") else { return jsonError("Missing subscriptionId") }
            let availability = try await self.repo.getAvailability(subscriptionId: subscriptionId)
            return try restFormat([availability])
        }
    }
}
