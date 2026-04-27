import Domain
import Foundation
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

        group.post("/apps/:appId/iap") { request, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let body = try await request.body.collect(upTo: 64 * 1024)
            let json = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            guard let referenceName = json["referenceName"] as? String else {
                return jsonError("Missing referenceName", status: .badRequest)
            }
            guard let productId = json["productId"] as? String else {
                return jsonError("Missing productId", status: .badRequest)
            }
            // Accept either cli-style ("non-consumable") or the raw enum ("NON_CONSUMABLE") —
            // frontends and CI scripts pick different conventions.
            guard let typeRaw = json["inAppPurchaseType"] as? String ?? json["type"] as? String,
                  let type = InAppPurchaseType(cliArgument: typeRaw) ?? InAppPurchaseType(rawValue: typeRaw) else {
                return jsonError("Missing or invalid inAppPurchaseType", status: .badRequest)
            }
            let created = try await self.repo.createInAppPurchase(
                appId: appId, referenceName: referenceName, productId: productId, type: type
            )
            return try restFormat(created)
        }

        group.patch("/iap/:iapId") { request, context -> Response in
            guard let iapId = context.parameters.get("iapId") else { return jsonError("Missing iapId") }
            let body = try await request.body.collect(upTo: 64 * 1024)
            let json = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            let updated = try await self.repo.updateInAppPurchase(
                iapId: iapId,
                referenceName: json["referenceName"] as? String,
                reviewNote: json["reviewNote"] as? String,
                isFamilySharable: json["isFamilySharable"] as? Bool
            )
            return try restFormat(updated)
        }

        group.delete("/iap/:iapId") { _, context -> Response in
            guard let iapId = context.parameters.get("iapId") else { return jsonError("Missing iapId") }
            try await self.repo.deleteInAppPurchase(iapId: iapId)
            return restResponse("{\"deleted\":true}")
        }
    }
}
