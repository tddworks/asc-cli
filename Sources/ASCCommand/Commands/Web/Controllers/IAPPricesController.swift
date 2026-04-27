import Domain
import Foundation
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes for setting (or changing) the manual base price of an IAP. Calling with a new
/// `baseTerritory` is how the iOS app implements "Change Base Territory" — ASC replaces
/// the previous schedule with a new one and equalizes other territories from the new base.
struct IAPPricesController: Sendable {
    let repo: any InAppPurchasePriceRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.post("/iap/:iapId/prices/set") { request, context -> Response in
            guard let iapId = context.parameters.get("iapId") else { return jsonError("Missing iapId") }
            let body = try await request.body.collect(upTo: 64 * 1024)
            let json = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            guard let baseTerritory = json["baseTerritory"] as? String ?? json["base-territory"] as? String else {
                return jsonError("Missing baseTerritory", status: .badRequest)
            }
            guard let pricePointId = json["pricePointId"] as? String ?? json["price-point-id"] as? String else {
                return jsonError("Missing pricePointId", status: .badRequest)
            }
            let schedule = try await self.repo.setPriceSchedule(
                iapId: iapId,
                baseTerritory: baseTerritory,
                pricePointId: pricePointId
            )
            return try restFormat([schedule])
        }
    }
}
