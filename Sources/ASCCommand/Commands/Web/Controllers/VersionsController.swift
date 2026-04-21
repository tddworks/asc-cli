import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return `AppStoreVersion` resources.
struct VersionsController: Sendable {
    let repo: any VersionRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/apps/:appId/versions") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let versions = try await self.repo.listVersions(appId: appId)
            return try restFormat(versions)
        }
    }
}
