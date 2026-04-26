import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return `SubscriptionPromotionalOffer` resources and their per-territory prices.
struct SubscriptionPromotionalOffersController: Sendable {
    let repo: any SubscriptionPromotionalOfferRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/subscriptions/:subscriptionId/subscription-promotional-offers") { _, context -> Response in
            guard let subscriptionId = context.parameters.get("subscriptionId") else { return jsonError("Missing subscriptionId") }
            let items = try await self.repo.listPromotionalOffers(subscriptionId: subscriptionId)
            return try restFormat(items)
        }

        group.get("/subscription-promotional-offers/:offerId/prices") { _, context -> Response in
            guard let offerId = context.parameters.get("offerId") else { return jsonError("Missing offerId") }
            let items = try await self.repo.listPrices(offerId: offerId)
            return try restFormat(items)
        }
    }
}
