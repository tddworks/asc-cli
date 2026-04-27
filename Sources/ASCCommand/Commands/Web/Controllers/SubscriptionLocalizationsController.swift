import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return `SubscriptionLocalization` resources.
struct SubscriptionLocalizationsController: Sendable {
    let repo: any SubscriptionLocalizationRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/subscriptions/:subscriptionId/localizations") { _, context -> Response in
            guard let subscriptionId = context.parameters.get("subscriptionId") else { return jsonError("Missing subscriptionId") }
            let items = try await self.repo.listLocalizations(subscriptionId: subscriptionId)
            return try restFormat(items)
        }
    }
}
