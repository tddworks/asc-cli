import Domain
import Foundation
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes for batch-setting per-territory prices on a subscription.
struct SubscriptionPricesController: Sendable {
    let repo: any SubscriptionPriceRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.post("/subscriptions/:subscriptionId/prices/set-batch") { request, context -> Response in
            guard let subscriptionId = context.parameters.get("subscriptionId") else {
                return jsonError("Missing subscriptionId")
            }
            let body = try await request.body.collect(upTo: 256 * 1024)
            let json = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            // Accept either `{ prices: [{territory, pricePointId, ...}] }` (preferred — mirrors
            // iOS's `setPrices(prices:)`) or a flat dict `{ "USA": "spp-1", "JPN": "spp-2" }`.
            var inputs: [SubscriptionPriceInput] = []
            if let array = json["prices"] as? [[String: Any]] {
                inputs = array.compactMap { entry -> SubscriptionPriceInput? in
                    guard let territory = entry["territory"] as? String,
                          let pricePointId = entry["pricePointId"] as? String ?? entry["price-point-id"] as? String
                    else { return nil }
                    return SubscriptionPriceInput(
                        territory: territory,
                        pricePointId: pricePointId,
                        startDate: entry["startDate"] as? String,
                        preserveCurrentPrice: entry["preserveCurrentPrice"] as? Bool
                    )
                }
            } else if let dict = json["prices"] as? [String: String] {
                inputs = dict.map { SubscriptionPriceInput(territory: $0.key, pricePointId: $0.value) }
            }
            guard !inputs.isEmpty else {
                return jsonError("Missing or empty prices", status: .badRequest)
            }
            let schedule = try await self.repo.setPrices(subscriptionId: subscriptionId, prices: inputs)
            return try restFormat([schedule])
        }
    }
}
