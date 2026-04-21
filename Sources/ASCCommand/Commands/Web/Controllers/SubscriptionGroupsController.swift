import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return `SubscriptionGroup` resources.
struct SubscriptionGroupsController: Sendable {
    let repo: any SubscriptionGroupRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/apps/:appId/subscription-groups") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let groups = try await self.repo.listSubscriptionGroups(appId: appId, limit: nil).data
            return try restFormat(groups)
        }
    }
}
