import Foundation
import ASCKit
import Hummingbird
import HummingbirdWebSocket

/// `GET /apps/:appId/availability` — the app's availability (`data: []` when never set up).
/// `POST /apps/:appId/availability` — set it up. Body keys match the CLI flags:
/// `{"territory": ["USA", "JPN"]}` or `{"all-territories": true}`, plus optional
/// `"available-in-new-territories": true`.
struct AppAvailabilityController: Sendable {
    let repo: any AppAvailabilities
    let territoryRepo: any Territories

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/apps/:appId/availability") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let availability = try await self.repo.getAppAvailability(appId: appId)
            return try restFormat(availability.map { [$0] } ?? [])
        }

        group.post("/apps/:appId/availability") { request, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let body = try await request.body.collect(upTo: 64 * 1024)
            let json = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            let territories = json["territory"] as? [String] ?? []
            let allTerritories = json["all-territories"] as? Bool ?? false
            guard allTerritories != !territories.isEmpty else {
                return jsonError("Body needs either territory: [...] or all-territories: true", status: .badRequest)
            }
            let territoryIds = allTerritories ? try await self.territoryRepo.listTerritories().map(\.id) : territories
            let availability = try await self.repo.createAppAvailability(
                appId: appId,
                isAvailableInNewTerritories: json["available-in-new-territories"] as? Bool ?? false,
                territoryIds: territoryIds
            )
            return try restFormat([availability])
        }
    }
}
