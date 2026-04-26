import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return IAP review screenshot + promotional images.
struct IAPReviewController: Sendable {
    let repo: any InAppPurchaseReviewRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/iap/:iapId/review-screenshot") { _, context -> Response in
            guard let iapId = context.parameters.get("iapId") else { return jsonError("Missing iapId") }
            let item = try await self.repo.getReviewScreenshot(iapId: iapId)
            return try restFormat(item.map { [$0] } ?? [])
        }

        group.get("/iap/:iapId/images") { _, context -> Response in
            guard let iapId = context.parameters.get("iapId") else { return jsonError("Missing iapId") }
            let items = try await self.repo.listImages(iapId: iapId)
            return try restFormat(items)
        }
    }
}
