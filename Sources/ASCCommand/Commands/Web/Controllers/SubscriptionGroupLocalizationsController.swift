import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return `SubscriptionGroupLocalization` resources.
struct SubscriptionGroupLocalizationsController: Sendable {
    let repo: any SubscriptionGroupLocalizationRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/subscription-groups/:groupId/subscription-group-localizations") { _, context -> Response in
            guard let groupId = context.parameters.get("groupId") else { return jsonError("Missing groupId") }
            let items = try await self.repo.listLocalizations(groupId: groupId)
            return try restFormat(items)
        }
    }
}
