import Domain
import Foundation
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

        group.post("/apps/:appId/subscription-groups") { request, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let body = try await request.body.collect(upTo: 64 * 1024)
            let json = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            guard let referenceName = json["referenceName"] as? String else {
                return jsonError("Missing referenceName", status: .badRequest)
            }
            let created = try await self.repo.createSubscriptionGroup(appId: appId, referenceName: referenceName)
            return try restFormat(created)
        }

        group.patch("/subscription-groups/:groupId") { request, context -> Response in
            guard let groupId = context.parameters.get("groupId") else { return jsonError("Missing groupId") }
            let body = try await request.body.collect(upTo: 64 * 1024)
            let json = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            guard let referenceName = json["referenceName"] as? String else {
                return jsonError("Missing referenceName", status: .badRequest)
            }
            let updated = try await self.repo.updateSubscriptionGroup(groupId: groupId, referenceName: referenceName)
            return try restFormat(updated)
        }

        group.delete("/subscription-groups/:groupId") { _, context -> Response in
            guard let groupId = context.parameters.get("groupId") else { return jsonError("Missing groupId") }
            try await self.repo.deleteSubscriptionGroup(groupId: groupId)
            return restResponse("{\"deleted\":true}")
        }
    }
}
