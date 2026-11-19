import ASCKit
import Hummingbird
import HummingbirdWebSocket

/// Routes that return `SubscriptionIntroductoryOffer` resources.
struct SubscriptionIntroductoryOffersController: Sendable {
    let repo: any SubscriptionIntroductoryOffers

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/subscriptions/:subscriptionId/introductory-offers") { _, context -> Response in
            guard let subscriptionId = context.parameters.get("subscriptionId") else { return jsonError("Missing subscriptionId") }
            let items = try await self.repo.listIntroductoryOffers(subscriptionId: subscriptionId)
            return try restFormat(items)
        }
    }
}
