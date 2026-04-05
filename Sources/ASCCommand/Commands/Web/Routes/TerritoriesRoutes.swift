import Hummingbird
import HummingbirdWebSocket
import ASCPlugin
import Infrastructure
import Domain

/// /api/v1/territories — Territory routes.
enum TerritoriesRoutes {
    static func register(on group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/territories") { _, _ -> Response in
            try await restExec { try await TerritoriesList.parse(["--pretty"]).execute(repo: ClientProvider.makeTerritoryRepository(), affordanceMode: .rest) }
        }
    }
}
