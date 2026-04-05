import Hummingbird
import HummingbirdWebSocket
import ASCPlugin
import Domain

/// /api/v1/plugins — Plugin routes.
struct PluginsController: Sendable {
    let repo: any PluginRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/plugins") { _, _ -> Response in
            let plugins = try await self.repo.listInstalled()
            return try restFormat(plugins)
        }

        group.get("/plugins/market") { _, _ -> Response in
            let plugins = try await self.repo.listAvailable()
            return try restFormat(plugins)
        }
    }
}
