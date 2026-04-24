import Domain
import Foundation
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return `App` resources.
struct AppsController: Sendable {
    let repo: any AppRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/apps") { request, _ -> Response in
            let includeIcon = (request.uri.queryParameters["include"].map(String.init) ?? "")
                .split(separator: ",")
                .contains("icon")
            let apps = try await Self.loadApps(repo: self.repo, includeIcon: includeIcon)
            return try restFormat(apps)
        }

        group.get("/apps/:appId") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let app = try await self.repo.getApp(id: appId)
            return try restFormat(app)
        }

        group.patch("/apps/:appId") { request, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let body = try await request.body.collect(upTo: 64 * 1024)
            let json = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            let rawDeclaration = json["contentRightsDeclaration"] as? String
            let declaration: ContentRightsDeclaration?
            if let raw = rawDeclaration {
                guard let parsed = ContentRightsDeclaration(rawValue: raw) else {
                    return jsonError("Unknown contentRightsDeclaration '\(raw)'", status: .badRequest)
                }
                declaration = parsed
            } else {
                declaration = nil
            }
            let updated = try await self.repo.updateContentRights(appId: appId, declaration: declaration)
            return try restFormat(updated)
        }
    }

    /// Load apps and, when requested, enrich each one with its icon asset.
    /// Icon fetch is parallel across apps; nil icons are tolerated.
    static func loadApps(repo: any AppRepository, includeIcon: Bool) async throws -> [App] {
        let apps = try await repo.listApps(limit: nil).data
        guard includeIcon else { return apps }

        let icons = await withTaskGroup(of: (String, ImageAsset?).self) { group in
            for app in apps {
                group.addTask {
                    let icon = try? await repo.fetchAppIcon(appId: app.id)
                    return (app.id, icon ?? nil)
                }
            }
            var byId: [String: ImageAsset] = [:]
            for await (id, asset) in group {
                if let asset { byId[id] = asset }
            }
            return byId
        }

        return apps.map { $0.with(iconAsset: icons[$0.id]) }
    }
}
