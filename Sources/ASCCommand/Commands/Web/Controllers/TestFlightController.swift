import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return TestFlight `BetaGroup` resources.
struct TestFlightController: Sendable {
    let repo: any TestFlightRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/apps/:appId/testflight") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let groups = try await self.repo.listBetaGroups(appId: appId, limit: nil).data
            return try restFormat(groups)
        }
    }
}
