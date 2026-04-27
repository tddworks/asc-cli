import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return the per-territory price schedule for a subscription.
struct SubscriptionPriceScheduleController: Sendable {
    let repo: any SubscriptionPriceRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/subscriptions/:subscriptionId/price-schedule") { _, context -> Response in
            guard let subscriptionId = context.parameters.get("subscriptionId") else {
                return jsonError("Missing subscriptionId")
            }
            let schedule = try await self.repo.getPriceSchedule(subscriptionId: subscriptionId)
            return try restFormat(schedule.map { [$0] } ?? [])
        }
    }
}
