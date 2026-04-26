import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return `PromotedPurchase` resources (App Store product page promoted slots).
struct PromotedPurchasesController: Sendable {
    let repo: any PromotedPurchaseRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/apps/:appId/promoted-purchases") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let items = try await self.repo.listPromotedPurchases(appId: appId, limit: nil).data
            return try restFormat(items)
        }
    }
}
