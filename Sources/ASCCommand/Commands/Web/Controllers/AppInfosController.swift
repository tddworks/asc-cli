import Domain
import Foundation
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return `AppInfo` and `AppInfoLocalization` resources.
struct AppInfosController: Sendable {
    let repo: any AppInfoRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/apps/:appId/app-infos") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let infos = try await self.repo.listAppInfos(appId: appId)
            return try restFormat(infos)
        }

        group.get("/app-infos/:appInfoId/localizations") { _, context -> Response in
            guard let appInfoId = context.parameters.get("appInfoId") else { return jsonError("Missing appInfoId") }
            let items = try await self.repo.listLocalizations(appInfoId: appInfoId)
            return try restFormat(items)
        }

        group.patch("/app-infos/:appInfoId") { request, context -> Response in
            guard let appInfoId = context.parameters.get("appInfoId") else { return jsonError("Missing appInfoId") }
            let body = try await request.body.collect(upTo: 64 * 1024)
            let json = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            let updated = try await self.repo.updateCategories(
                id: appInfoId,
                primaryCategoryId: json["primaryCategoryId"] as? String,
                primarySubcategoryOneId: json["primarySubcategoryOneId"] as? String,
                primarySubcategoryTwoId: json["primarySubcategoryTwoId"] as? String,
                secondaryCategoryId: json["secondaryCategoryId"] as? String,
                secondarySubcategoryOneId: json["secondarySubcategoryOneId"] as? String,
                secondarySubcategoryTwoId: json["secondarySubcategoryTwoId"] as? String
            )
            return try restFormat(updated)
        }
    }
}
