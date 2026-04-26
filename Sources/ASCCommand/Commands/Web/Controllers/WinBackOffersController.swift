import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return `WinBackOffer` resources and their per-territory prices.
struct WinBackOffersController: Sendable {
    let repo: any WinBackOfferRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/subscriptions/:subscriptionId/win-back-offers") { _, context -> Response in
            guard let subscriptionId = context.parameters.get("subscriptionId") else { return jsonError("Missing subscriptionId") }
            let items = try await self.repo.listWinBackOffers(subscriptionId: subscriptionId)
            return try restFormat(items)
        }

        group.get("/win-back-offers/:offerId/prices") { _, context -> Response in
            guard let offerId = context.parameters.get("offerId") else { return jsonError("Missing offerId") }
            let items = try await self.repo.listPrices(offerId: offerId)
            return try restFormat(items)
        }
    }
}
