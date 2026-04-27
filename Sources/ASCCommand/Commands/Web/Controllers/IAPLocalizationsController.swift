import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return `InAppPurchaseLocalization` resources.
struct IAPLocalizationsController: Sendable {
    let repo: any InAppPurchaseLocalizationRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/iap/:iapId/localizations") { _, context -> Response in
            guard let iapId = context.parameters.get("iapId") else { return jsonError("Missing iapId") }
            let items = try await self.repo.listLocalizations(iapId: iapId)
            return try restFormat(items)
        }
    }
}
