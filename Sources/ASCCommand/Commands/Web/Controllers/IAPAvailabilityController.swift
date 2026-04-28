import Domain
import Foundation
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return the per-territory availability of an in-app purchase.
struct IAPAvailabilityController: Sendable {
    let repo: any InAppPurchaseAvailabilityRepository
    /// Used to seed a synthetic "all 175 territories available" response when ASC has no
    /// availability resource yet — matches the iOS app's default UX for fresh IAPs (the
    /// view defaults `selectedIds = Set(app.territories.map(\.id))`).
    let territoryRepo: any TerritoryRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/iap/:iapId/availability") { _, context -> Response in
            guard let iapId = context.parameters.get("iapId") else { return jsonError("Missing iapId") }
            if let availability = try await self.repo.getAvailability(iapId: iapId) {
                return try restFormat([availability])
            }
            // No availability resource yet — synthesize one with all territories selected,
            // matching iOS's default UX. Frontend treats `id == iapId` as "not yet
            // configured" and POSTs to create on first save.
            let territories = (try? await self.territoryRepo.listTerritories()) ?? []
            let synthetic = InAppPurchaseAvailability(
                id: iapId, iapId: iapId,
                isAvailableInNewTerritories: true,
                territories: territories
            )
            return try restFormat([synthetic])
        }

        // PATCH = upsert: ASC's POST /v1/inAppPurchaseAvailabilities is the only mutation
        // it exposes for this resource and acts as a replace when the IAP already has one.
        // The frontend uses PATCH semantically (modify existing territories) — same SDK call.
        group.patch("/iap/:iapId/availability") { request, context -> Response in
            guard let iapId = context.parameters.get("iapId") else { return jsonError("Missing iapId") }
            let body = try await request.body.collect(upTo: 64 * 1024)
            let json = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            let territoryIds = json["territoryIds"] as? [String] ?? []
            let availableInNew = json["availableInNewTerritories"] as? Bool ?? false
            let availability = try await self.repo.createAvailability(
                iapId: iapId,
                isAvailableInNewTerritories: availableInNew,
                territoryIds: territoryIds
            )
            return try restFormat([availability])
        }
    }
}
