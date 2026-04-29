import Domain
import Foundation
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return `SubscriptionGroupLocalization` resources.
struct SubscriptionGroupLocalizationsController: Sendable {
    let repo: any SubscriptionGroupLocalizationRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/subscription-groups/:groupId/subscription-group-localizations") { _, context -> Response in
            guard let groupId = context.parameters.get("groupId") else { return jsonError("Missing groupId") }
            let items = try await self.repo.listLocalizations(groupId: groupId)
            return try restFormat(items)
        }

        group.post("/subscription-groups/:groupId/subscription-group-localizations") { request, context -> Response in
            guard let groupId = context.parameters.get("groupId") else { return jsonError("Missing groupId") }
            let body = try await request.body.collect(upTo: 64 * 1024)
            let json = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            guard let locale = json["locale"] as? String else {
                return jsonError("Missing locale", status: .badRequest)
            }
            guard let name = json["name"] as? String else {
                return jsonError("Missing name", status: .badRequest)
            }
            let created = try await self.repo.createLocalization(
                groupId: groupId,
                locale: locale,
                name: name,
                customAppName: json["customAppName"] as? String
            )
            return try restFormat(created)
        }

        group.patch("/subscription-group-localizations/:localizationId") { request, context -> Response in
            guard let localizationId = context.parameters.get("localizationId") else { return jsonError("Missing localizationId") }
            let body = try await request.body.collect(upTo: 64 * 1024)
            let json = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            let updated = try await self.repo.updateLocalization(
                localizationId: localizationId,
                name: json["name"] as? String,
                customAppName: json["customAppName"] as? String
            )
            return try restFormat(updated)
        }

        group.delete("/subscription-group-localizations/:localizationId") { _, context -> Response in
            guard let localizationId = context.parameters.get("localizationId") else { return jsonError("Missing localizationId") }
            try await self.repo.deleteLocalization(localizationId: localizationId)
            return restResponse("{\"deleted\":true}")
        }
    }
}
