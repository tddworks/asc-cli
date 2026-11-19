import ASCKit
import Hummingbird
import HummingbirdWebSocket

/// Review versions of in-app purchases, subscriptions and subscription groups.
/// A submittable version is sent to review by adding it to a review submission.
struct ProductVersionsController: Sendable {
    let repo: any ProductVersionRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/iap/:iapId/versions") { _, context -> Response in
            guard let iapId = context.parameters.get("iapId") else { return jsonError("Missing iapId") }
            return try restFormat(try await self.repo.listInAppPurchaseVersions(iapId: iapId))
        }

        group.get("/subscriptions/:subscriptionId/versions") { _, context -> Response in
            guard let subscriptionId = context.parameters.get("subscriptionId") else { return jsonError("Missing subscriptionId") }
            return try restFormat(try await self.repo.listSubscriptionVersions(subscriptionId: subscriptionId))
        }

        group.get("/subscription-groups/:groupId/versions") { _, context -> Response in
            guard let groupId = context.parameters.get("groupId") else { return jsonError("Missing groupId") }
            return try restFormat(try await self.repo.listSubscriptionGroupVersions(groupId: groupId))
        }
    }
}
