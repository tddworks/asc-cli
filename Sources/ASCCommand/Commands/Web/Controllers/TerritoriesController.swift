import Hummingbird
import HummingbirdWebSocket
import ASCPlugin
import Domain

/// /api/v1/territories — Territory routes.
struct TerritoriesController: Sendable {
    let repo: any TerritoryRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/territories") { _, _ -> Response in
            let territories = try await self.repo.listTerritories()
            return try restFormat(territories)
        }
    }
}
