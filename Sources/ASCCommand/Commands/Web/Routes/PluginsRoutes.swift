import Hummingbird
import HummingbirdWebSocket
import ASCPlugin
import Infrastructure
import Domain

/// /api/v1/plugins — Plugin routes.
enum PluginsRoutes {
    static func register(on group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/plugins") { _, _ -> Response in
            let plugins = try await ClientProvider.makePluginRepository().listInstalled()
            return try restFormat(plugins)
        }

        group.get("/plugins/market") { _, _ -> Response in
            let plugins = try await ClientProvider.makePluginRepository().listAvailable()
            return try restFormat(plugins)
        }
    }
}
