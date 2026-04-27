import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return `Subscription` resources nested under a subscription group.
struct SubscriptionsController: Sendable {
    let repo: any SubscriptionRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/subscription-groups/:groupId/subscriptions") { request, context -> Response in
            guard let groupId = context.parameters.get("groupId") else { return jsonError("Missing groupId") }
            let limit = request.uri.queryParameters.get("limit").flatMap { Int($0) }
            let response = try await self.repo.listSubscriptions(groupId: groupId, limit: limit)
            return try restFormat(response.data)
        }
    }
}
