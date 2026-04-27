import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return Apple's auto-equalized territory prices for an IAP price point.
struct IAPEqualizationsController: Sendable {
    let repo: any InAppPurchasePriceRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/iap-price-points/:pricePointId/equalizations") { request, context -> Response in
            guard let pricePointId = context.parameters.get("pricePointId") else {
                return jsonError("Missing pricePointId")
            }
            let limit = request.uri.queryParameters.get("limit").flatMap { Int($0) }
            let items = try await self.repo.listEqualizations(pricePointId: pricePointId, limit: limit)
            return try restFormat(items)
        }
    }
}
