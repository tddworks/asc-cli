import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return `InAppPurchasePricePoint` resources.
struct IAPPricePointsController: Sendable {
    let repo: any InAppPurchasePriceRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/iap/:iapId/price-points") { request, context -> Response in
            guard let iapId = context.parameters.get("iapId") else { return jsonError("Missing iapId") }
            let territory = request.uri.queryParameters.get("territory").flatMap { String($0) }
            let items = try await self.repo.listPricePoints(iapId: iapId, territory: territory)
            return try restFormat(items)
        }
    }
}
