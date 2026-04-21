import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return `AppScreenshotSet` resources.
struct ScreenshotSetsController: Sendable {
    let repo: any ScreenshotRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/version-localizations/:localizationId/screenshot-sets") { _, context -> Response in
            guard let localizationId = context.parameters.get("localizationId") else { return jsonError("Missing localizationId") }
            let sets = try await self.repo.listScreenshotSets(localizationId: localizationId)
            return try restFormat(sets)
        }
    }
}
