import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return `InAppPurchaseOfferCode` resources.
struct IAPOfferCodesController: Sendable {
    let repo: any InAppPurchaseOfferCodeRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/iap/:iapId/offer-codes") { _, context -> Response in
            guard let iapId = context.parameters.get("iapId") else { return jsonError("Missing iapId") }
            let items = try await self.repo.listOfferCodes(iapId: iapId)
            return try restFormat(items)
        }
    }
}
