import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return the manual price schedule for an in-app purchase.
struct IAPPriceScheduleController: Sendable {
    let repo: any InAppPurchasePriceRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/iap/:iapId/price-schedule") { _, context -> Response in
            guard let iapId = context.parameters.get("iapId") else { return jsonError("Missing iapId") }
            // 404 from upstream → empty `data: []` so agents can navigate; presence of any
            // entry signals the schedule exists.
            let schedule = try await self.repo.getPriceSchedule(iapId: iapId)
            return try restFormat(schedule.map { [$0] } ?? [])
        }
    }
}
