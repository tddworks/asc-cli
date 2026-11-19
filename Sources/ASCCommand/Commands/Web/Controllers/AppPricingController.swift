import Foundation
import ASCKit
import Hummingbird
import HummingbirdWebSocket

/// App pricing (mirrors `IAPPricePointsController` / `IAPPricesController`):
/// `GET /apps/:appId/price-points?territory=USA` and `POST /apps/:appId/prices/set`
/// with body `{"base-territory": "USA", "price-point-id": "…"}` (camelCase keys also accepted).
struct AppPricingController: Sendable {
    let repo: any PricingRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/apps/:appId/price-points") { request, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let territory = request.uri.queryParameters.get("territory").map { String($0) } ?? "USA"
            return try restFormat(try await self.repo.listPricePoints(appId: appId, territory: territory))
        }

        group.post("/apps/:appId/prices/set") { request, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let body = try await request.body.collect(upTo: 64 * 1024)
            let json = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            guard let baseTerritory = json["base-territory"] as? String ?? json["baseTerritory"] as? String else {
                return jsonError("Missing base-territory", status: .badRequest)
            }
            guard let pricePointId = json["price-point-id"] as? String ?? json["pricePointId"] as? String else {
                return jsonError("Missing price-point-id", status: .badRequest)
            }
            let schedule = try await self.repo.setPriceSchedule(
                appId: appId, baseTerritory: baseTerritory, pricePointId: pricePointId
            )
            return try restFormat([schedule])
        }
    }
}
