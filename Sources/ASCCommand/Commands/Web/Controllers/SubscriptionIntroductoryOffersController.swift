import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return `SubscriptionIntroductoryOffer` resources.
struct SubscriptionIntroductoryOffersController: Sendable {
    let repo: any SubscriptionIntroductoryOfferRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/subscriptions/:subscriptionId/introductory-offers") { _, context -> Response in
            guard let subscriptionId = context.parameters.get("subscriptionId") else { return jsonError("Missing subscriptionId") }
            let items = try await self.repo.listIntroductoryOffers(subscriptionId: subscriptionId)
            return try restFormat(items)
        }
    }
}
