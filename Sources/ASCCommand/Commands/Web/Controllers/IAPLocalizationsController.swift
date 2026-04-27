import Domain
import Foundation
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// ASC's IAP localization field constraints. Public so future controllers and validators
/// can stay in sync with the iOS app's `LocaleCard` limits (`limit: 30` / `limit: 45`).
enum IAPLocalizationLimits {
    static let nameMaxChars = 30
    static let descriptionMaxChars = 45
}

/// Trims to the given grapheme-cluster count. ASC counts characters the same way Swift's
/// `String.count` does, so `.prefix(_:)` matches what the iOS view counter shows.
private func clamp(_ value: String, to limit: Int) -> String {
    value.count <= limit ? value : String(value.prefix(limit))
}

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
            // ASC enforces field constraints (name ≤30, description ≤45 grapheme clusters).
            // Trim before sending so callers don't have to validate client-side, and surface
            // any remaining ASC error (e.g. invalid locale) as a 400 with the real message
            // instead of Hummingbird's generic empty 500.
            let trimmedName = clamp(name, to: IAPLocalizationLimits.nameMaxChars)
            let trimmedDescription = (json["description"] as? String).map {
                clamp($0, to: IAPLocalizationLimits.descriptionMaxChars)
            }
            do {
                let created = try await self.repo.createLocalization(
                    iapId: iapId,
                    locale: locale,
                    name: trimmedName,
                    description: trimmedDescription
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
            // Trim to ASC's limits (name ≤30, description ≤45) — same reasoning as POST.
            let trimmedName = (json["name"] as? String).map {
                clamp($0, to: IAPLocalizationLimits.nameMaxChars)
            }
            let trimmedDescription = (json["description"] as? String).map {
                clamp($0, to: IAPLocalizationLimits.descriptionMaxChars)
            }
            do {
                let updated = try await self.repo.updateLocalization(
                    localizationId: localizationId,
                    name: trimmedName,
                    description: trimmedDescription
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
