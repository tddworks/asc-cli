import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return per-territory prices attached to IAP and subscription offer codes.
struct OfferCodePricesController: Sendable {
    let iapRepo: any InAppPurchaseOfferCodeRepository
    let subRepo: any SubscriptionOfferCodeRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/iap-offer-codes/:offerCodeId/prices") { _, context -> Response in
            guard let offerCodeId = context.parameters.get("offerCodeId") else { return jsonError("Missing offerCodeId") }
            let items = try await self.iapRepo.listPrices(offerCodeId: offerCodeId)
            return try restFormat(items)
        }

        group.get("/subscription-offer-codes/:offerCodeId/prices") { _, context -> Response in
            guard let offerCodeId = context.parameters.get("offerCodeId") else { return jsonError("Missing offerCodeId") }
            let items = try await self.subRepo.listPrices(offerCodeId: offerCodeId)
            return try restFormat(items)
        }
    }
}
