import Domain
import Foundation
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

        group.patch("/subscriptions/:subscriptionId") { request, context -> Response in
            guard let subscriptionId = context.parameters.get("subscriptionId") else { return jsonError("Missing subscriptionId") }
            let body = try await request.body.collect(upTo: 64 * 1024)
            let json = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            return try restFormat(try await Self.update(subscriptionId: subscriptionId, json: json, repo: self.repo))
        }
    }

    /// Body keys mirror the `asc subscriptions update` flags in camelCase.
    static func update(
        subscriptionId: String,
        json: [String: Any],
        repo: any SubscriptionRepository
    ) async throws -> Subscription {
        let marketSettings = (json["marketSetting"] as? [String])?.compactMap(SubscriptionMarketSetting.init(rawValue:))
        return try await repo.updateSubscription(
            subscriptionId: subscriptionId,
            name: json["name"] as? String,
            isFamilySharable: json["familySharable"] as? Bool,
            groupLevel: json["groupLevel"] as? Int,
            subscriptionPeriod: (json["period"] as? String).flatMap(SubscriptionPeriod.init(rawValue:)),
            reviewNote: json["reviewNote"] as? String,
            multiSeatStatus: (json["multiSeatStatus"] as? String).flatMap(SubscriptionMultiSeatStatus.init(rawValue:)),
            marketSettings: marketSettings
        )
    }
}
