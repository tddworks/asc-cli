import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return `BetaAppLocalization` resources.
struct BetaAppLocalizationsController: Sendable {
    let repo: any BetaAppLocalizationRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/apps/:appId/beta-app-localizations") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let items = try await self.repo.listBetaAppLocalizations(appId: appId)
            return try restFormat(items)
        }

        group.get("/beta-app-localizations/:localizationId") { _, context -> Response in
            guard let id = context.parameters.get("localizationId") else { return jsonError("Missing localizationId") }
            let item = try await self.repo.getBetaAppLocalization(localizationId: id)
            return try restFormat(item)
        }
    }
}
