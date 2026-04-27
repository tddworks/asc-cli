import Domain
import Foundation
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

        group.post("/iap/:iapId/localizations") { request, context -> Response in
            guard let iapId = context.parameters.get("iapId") else { return jsonError("Missing iapId") }
            let body = try await request.body.collect(upTo: 64 * 1024)
            let json = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            guard let locale = json["locale"] as? String else {
                return jsonError("Missing locale", status: .badRequest)
            }
            guard let name = json["name"] as? String else {
                return jsonError("Missing name", status: .badRequest)
            }
            let created = try await self.repo.createLocalization(
                iapId: iapId,
                locale: locale,
                name: name,
                description: json["description"] as? String
            )
            return try restFormat(created)
        }

        group.patch("/iap-localizations/:localizationId") { request, context -> Response in
            guard let localizationId = context.parameters.get("localizationId") else {
                return jsonError("Missing localizationId")
            }
            let body = try await request.body.collect(upTo: 64 * 1024)
            let json = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            let updated = try await self.repo.updateLocalization(
                localizationId: localizationId,
                name: json["name"] as? String,
                description: json["description"] as? String
            )
            return try restFormat(updated)
        }

        group.delete("/iap-localizations/:localizationId") { _, context -> Response in
            guard let localizationId = context.parameters.get("localizationId") else {
                return jsonError("Missing localizationId")
            }
            try await self.repo.deleteLocalization(localizationId: localizationId)
            return restResponse("{\"deleted\":true}")
        }
    }
}
