import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return `InAppPurchase` resources.
struct IAPController: Sendable {
    let repo: any InAppPurchaseRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/apps/:appId/iap") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let iaps = try await self.repo.listInAppPurchases(appId: appId, limit: nil).data
            return try restFormat(iaps)
        }
    }
}
