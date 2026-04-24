import Domain
import Foundation
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Returns the String value for a JSON key, or nil if missing/null.
/// Use this for PATCH bodies where an absent key means "don't change".
private func optionalString(_ value: Any?) -> String? {
    guard let value = value, !(value is NSNull) else { return nil }
    return value as? String
}

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

        group.post("/app-infos/:appInfoId/localizations") { request, context -> Response in
            guard let appInfoId = context.parameters.get("appInfoId") else { return jsonError("Missing appInfoId") }
            let body = try await request.body.collect(upTo: 64 * 1024)
            let json = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            guard let locale = json["locale"] as? String, !locale.isEmpty else {
                return jsonError("Missing locale", status: .badRequest)
            }
            let name = (json["name"] as? String) ?? ""
            let created = try await self.repo.createLocalization(
                appInfoId: appInfoId,
                locale: locale,
                name: name
            )
            return try restFormat(created)
        }

        group.patch("/app-info-localizations/:localizationId") { request, context -> Response in
            guard let localizationId = context.parameters.get("localizationId") else { return jsonError("Missing localizationId") }
            let body = try await request.body.collect(upTo: 64 * 1024)
            let json = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            let updated = try await self.repo.updateLocalization(
                id: localizationId,
                name: optionalString(json["name"]),
                subtitle: optionalString(json["subtitle"]),
                privacyPolicyUrl: optionalString(json["privacyPolicyUrl"]),
                privacyChoicesUrl: optionalString(json["privacyChoicesUrl"]),
                privacyPolicyText: optionalString(json["privacyPolicyText"])
            )
            return try restFormat(updated)
        }

        group.delete("/app-info-localizations/:localizationId") { _, context -> Response in
            guard let localizationId = context.parameters.get("localizationId") else { return jsonError("Missing localizationId") }
            try await self.repo.deleteLocalization(id: localizationId)
            return Response(status: .noContent)
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
