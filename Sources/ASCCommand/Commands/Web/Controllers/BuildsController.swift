import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return `Build` resources (both fleet and per-app listings).
struct BuildsController: Sendable {
    let repo: any BuildRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/apps/:appId/builds") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let builds = try await self.repo.listBuilds(appId: appId, platform: nil, version: nil, limit: nil).data
            return try restFormat(builds)
        }

        // Fleet listing — ASC builds endpoint allows filtering by app or listing all.
        group.get("/builds") { request, _ -> Response in
            let query = request.uri.queryParameters
            let appId = query["app-id"].map(String.init)
            let platform = query["platform"].flatMap { BuildUploadPlatform(cliArgument: String($0)) }
            let version = query["version"].map(String.init)
            let limit = query["limit"].flatMap { Int($0) }
            let builds = try await self.repo.listBuilds(
                appId: appId,
                platform: platform,
                version: version,
                limit: limit
            ).data
            return try restFormat(builds)
        }
    }
}
