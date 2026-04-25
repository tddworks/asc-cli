import ASCPlugin
import Domain
import Foundation
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// /api/v1/plugins — Plugin routes.
///
/// Mirrors `asc plugins`:
///   GET    /plugins              ↔ asc plugins list
///   POST   /plugins              ↔ asc plugins install        (body: { "name": "..." })
///   DELETE /plugins/:name        ↔ asc plugins uninstall --name X
///   GET    /plugins/market       ↔ asc plugins market list
///   GET    /plugins/market?q=…   ↔ asc plugins market search --query …
struct PluginsController: Sendable {
    let repo: any PluginRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/plugins") { _, _ -> Response in
            let plugins = try await self.repo.listInstalled()
            return try restFormat(plugins)
        }

        group.post("/plugins") { request, _ -> Response in
            let body = try await request.body.collect(upTo: 64 * 1024)
            let json = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            guard let name = json["name"] as? String, !name.isEmpty else {
                return jsonError("Missing name", status: .badRequest)
            }
            let installed = try await self.repo.install(name: name)
            return try restFormat(installed)
        }

        group.delete("/plugins/:name") { _, context -> Response in
            guard let name = context.parameters.get("name") else { return jsonError("Missing name") }
            try await self.repo.uninstall(name: name)
            return Response(status: .noContent)
        }

        group.get("/plugins/market") { request, _ -> Response in
            let q = request.uri.queryParameters["q"].map(String.init) ?? ""
            let plugins: [Plugin]
            if q.isEmpty {
                plugins = try await self.repo.listAvailable()
            } else {
                plugins = try await self.repo.searchAvailable(query: q)
            }
            return try restFormat(plugins)
        }

        group.get("/plugins/updates") { _, _ -> Response in
            let updates = try await self.repo.listOutdated()
            return try restFormat(updates)
        }

        group.post("/plugins/:name/update") { _, context -> Response in
            guard let name = context.parameters.get("name") else { return jsonError("Missing name") }
            let updated = try await self.repo.update(name: name)
            return try restFormat(updated)
        }
    }
}
