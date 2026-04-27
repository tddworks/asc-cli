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
            // ASC enforces field constraints (name ≤30, description ≤45 chars) and validates
            // the locale code. Without an explicit catch, Hummingbird returns a generic 500
            // with no body and the browser shows "Failed to fetch". Surface the underlying
            // message so the UI can render ASC's actual reason.
            do {
                let created = try await self.repo.createLocalization(
                    iapId: iapId,
                    locale: locale,
                    name: name,
                    description: json["description"] as? String
                )
                return try restFormat(created)
            } catch {
                return jsonError(error.localizedDescription, status: .badRequest)
            }
        }

        group.patch("/iap-localizations/:localizationId") { request, context -> Response in
            guard let localizationId = context.parameters.get("localizationId") else {
                return jsonError("Missing localizationId")
            }
            let body = try await request.body.collect(upTo: 64 * 1024)
            let json = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            do {
                let updated = try await self.repo.updateLocalization(
                    localizationId: localizationId,
                    name: json["name"] as? String,
                    description: json["description"] as? String
                )
                return try restFormat(updated)
            } catch {
                return jsonError(error.localizedDescription, status: .badRequest)
            }
        }

        group.delete("/iap-localizations/:localizationId") { _, context -> Response in
            guard let localizationId = context.parameters.get("localizationId") else {
                return jsonError("Missing localizationId")
            }
            do {
                try await self.repo.deleteLocalization(localizationId: localizationId)
                return restResponse("{\"deleted\":true}")
            } catch {
                return jsonError(error.localizedDescription, status: .badRequest)
            }
        }
    }
}
