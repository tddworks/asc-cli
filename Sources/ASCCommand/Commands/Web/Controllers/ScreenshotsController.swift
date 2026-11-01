import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return `AppScreenshot` resources.
struct ScreenshotsController: Sendable {
    let repo: any ScreenshotRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/screenshot-sets/:setId/screenshots") { _, context -> Response in
            guard let setId = context.parameters.get("setId") else { return jsonError("Missing setId") }
            let shots = try await self.repo.listScreenshots(setId: setId)
            return try restFormat(shots)
        }

        group.delete("/screenshots/:screenshotId") { _, context -> Response in
            guard let screenshotId = context.parameters.get("screenshotId") else { return jsonError("Missing screenshotId") }
            try await self.repo.deleteScreenshot(screenshotId: screenshotId)
            return restResponse("{\"deleted\":true}")
        }
    }
}
