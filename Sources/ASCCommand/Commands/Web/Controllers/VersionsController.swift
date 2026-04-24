import Domain
import Foundation
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return `AppStoreVersion` resources.
struct VersionsController: Sendable {
    let repo: any VersionRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/apps/:appId/versions") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let versions = try await self.repo.listVersions(appId: appId)
            return try restFormat(versions)
        }

        group.post("/apps/:appId/versions") { request, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let body = try await request.body.collect(upTo: 64 * 1024)
            let json = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            guard let versionString = json["versionString"] as? String else {
                return jsonError("Missing versionString", status: .badRequest)
            }
            guard let platformRaw = json["platform"] as? String,
                  let platform = AppStorePlatform(cliArgument: platformRaw) ?? AppStorePlatform(rawValue: platformRaw) else {
                return jsonError("Missing or invalid platform", status: .badRequest)
            }
            let created = try await self.repo.createVersion(appId: appId, versionString: versionString, platform: platform)
            return try restFormat(created)
        }

        group.patch("/versions/:versionId") { request, context -> Response in
            guard let versionId = context.parameters.get("versionId") else { return jsonError("Missing versionId") }
            let body = try await request.body.collect(upTo: 64 * 1024)
            let json = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            guard let versionString = json["versionString"] as? String else {
                return jsonError("Missing versionString", status: .badRequest)
            }
            let updated = try await self.repo.updateVersion(id: versionId, versionString: versionString)
            return try restFormat(updated)
        }
    }
}
