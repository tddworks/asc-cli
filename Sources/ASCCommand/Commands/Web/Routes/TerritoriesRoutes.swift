import Hummingbird
import HummingbirdWebSocket
import ASCPlugin
import Infrastructure
import Domain

/// /api/v1/territories — Territory routes.
enum TerritoriesRoutes {
    static func register(on group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/territories") { _, _ -> Response in
            let territories = try await ClientProvider.makeTerritoryRepository().listTerritories()
            return try restFormat(territories)
        }
    }
}
