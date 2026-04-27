import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return the per-territory availability of an in-app purchase.
struct IAPAvailabilityController: Sendable {
    let repo: any InAppPurchaseAvailabilityRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/iap/:iapId/availability") { _, context -> Response in
            guard let iapId = context.parameters.get("iapId") else { return jsonError("Missing iapId") }
            let availability = try await self.repo.getAvailability(iapId: iapId)
            return try restFormat([availability])
        }
    }
}
