import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return `AppStoreVersionLocalization` resources.
struct VersionLocalizationsController: Sendable {
    let repo: any VersionLocalizationRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/versions/:versionId/localizations") { _, context -> Response in
            guard let versionId = context.parameters.get("versionId") else { return jsonError("Missing versionId") }
            let localizations = try await self.repo.listLocalizations(versionId: versionId)
            return try restFormat(localizations)
        }
    }
}
