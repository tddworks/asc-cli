import Hummingbird
import HummingbirdWebSocket
import ASCPlugin
import Infrastructure
import Domain

/// /api/v1/plugins — Plugin routes.
enum PluginsRoutes {
    static func register(on group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/plugins") { _, _ -> Response in
            try await restExec { try await PluginsList.parse(["--pretty"]).execute(repo: ClientProvider.makePluginRepository(), affordanceMode: .rest) }
        }

        group.get("/plugins/market") { _, _ -> Response in
            try await restExec { try await MarketList.parse(["--pretty"]).execute(repo: ClientProvider.makePluginRepository(), affordanceMode: .rest) }
        }
    }
}
