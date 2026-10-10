import Foundation
import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// `GET /apps/:appId/perf-overview?device-type=…` — the app's Xcode Organizer overview.
/// The query param matches the CLI flag `--device-type`.
struct PerfOverviewController: Sendable {
    let repo: any PerfOverviewRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/apps/:appId/perf-overview") { request, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let deviceType = request.uri.queryParameters.get("device-type").map { String($0) }
            let overview = try await self.repo.getOverview(appId: appId, deviceType: deviceType)
            return try restFormat([overview])
        }
    }
}
