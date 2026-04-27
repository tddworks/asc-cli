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
            let limit = request.uri.queryParameters.get("limit").flatMap { Int($0) }
            let cursor = request.uri.queryParameters.get("cursor").flatMap { String($0) }
            let response = try await self.repo.listPricePoints(
                subscriptionId: subscriptionId, territory: territory, limit: limit, cursor: cursor
            )
            return try restFormatPaginated(response)
        }
    }
}
