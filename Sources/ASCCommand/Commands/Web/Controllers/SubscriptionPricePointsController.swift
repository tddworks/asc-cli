import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return `SubscriptionPricePoint` resources.
struct SubscriptionPricePointsController: Sendable {
    let repo: any SubscriptionPriceRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/subscriptions/:subscriptionId/price-points") { request, context -> Response in
            guard let subscriptionId = context.parameters.get("subscriptionId") else { return jsonError("Missing subscriptionId") }
            let territory = request.uri.queryParameters.get("territory").flatMap { String($0) }
            let items = try await self.repo.listPricePoints(subscriptionId: subscriptionId, territory: territory)
            return try restFormat(items)
        }
    }
}
