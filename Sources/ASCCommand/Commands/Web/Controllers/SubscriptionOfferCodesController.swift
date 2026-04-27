import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return `SubscriptionOfferCode` resources.
struct SubscriptionOfferCodesController: Sendable {
    let repo: any SubscriptionOfferCodeRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/subscriptions/:subscriptionId/offer-codes") { _, context -> Response in
            guard let subscriptionId = context.parameters.get("subscriptionId") else { return jsonError("Missing subscriptionId") }
            let items = try await self.repo.listOfferCodes(subscriptionId: subscriptionId)
            return try restFormat(items)
        }
    }
}
