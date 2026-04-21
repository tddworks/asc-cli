import Domain
import Hummingbird
import HummingbirdWebSocket
import ASCPlugin
import Infrastructure

/// /api/v1/apps — App and child resource routes.
/// Dependencies injected at init, not constructed per request.
struct AppsController: Sendable {
    let appRepo: any AppRepository
    let versionRepo: any VersionRepository
    let localizationRepo: any VersionLocalizationRepository
    let buildRepo: any BuildRepository
    let testFlightRepo: any TestFlightRepository
    let reviewRepo: any CustomerReviewRepository
    let iapRepo: any InAppPurchaseRepository
    let subscriptionGroupRepo: any SubscriptionGroupRepository
    let appInfoRepo: any AppInfoRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/apps") { request, _ -> Response in
            let includeIcon = (request.uri.queryParameters["include"].map(String.init) ?? "")
                .split(separator: ",")
                .contains("icon")
            let apps = try await Self.loadApps(repo: self.appRepo, includeIcon: includeIcon)
            return try restFormat(apps)
        }

        group.get("/apps/:appId") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let app = try await self.appRepo.getApp(id: appId)
            return try restFormat(app)
        }

        group.get("/apps/:appId/versions") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let versions = try await self.versionRepo.listVersions(appId: appId)
            return try restFormat(versions)
        }

        group.get("/versions/:versionId/localizations") { _, context -> Response in
            guard let versionId = context.parameters.get("versionId") else { return jsonError("Missing versionId") }
            let localizations = try await self.localizationRepo.listLocalizations(versionId: versionId)
            return try restFormat(localizations)
        }

        group.get("/apps/:appId/builds") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let builds = try await self.buildRepo.listBuilds(appId: appId, platform: nil, version: nil, limit: nil).data
            return try restFormat(builds)
        }

        // Fleet listing — ASC builds endpoint allows filtering by app or listing all.
        group.get("/builds") { request, _ -> Response in
            let query = request.uri.queryParameters
            let appId = query["app-id"].map(String.init)
            let platform = query["platform"].flatMap { BuildUploadPlatform(cliArgument: String($0)) }
            let version = query["version"].map(String.init)
            let limit = query["limit"].flatMap { Int($0) }
            let builds = try await self.buildRepo.listBuilds(
                appId: appId,
                platform: platform,
                version: version,
                limit: limit
            ).data
            return try restFormat(builds)
        }

        group.get("/apps/:appId/testflight") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let groups = try await self.testFlightRepo.listBetaGroups(appId: appId, limit: nil).data
            return try restFormat(groups)
        }

        group.get("/apps/:appId/reviews") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let reviews = try await self.reviewRepo.listReviews(appId: appId)
            return try restFormat(reviews)
        }

        group.get("/apps/:appId/iap") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let iaps = try await self.iapRepo.listInAppPurchases(appId: appId, limit: nil).data
            return try restFormat(iaps)
        }

        group.get("/apps/:appId/subscription-groups") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let groups = try await self.subscriptionGroupRepo.listSubscriptionGroups(appId: appId, limit: nil).data
            return try restFormat(groups)
        }

        group.get("/apps/:appId/app-infos") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let infos = try await self.appInfoRepo.listAppInfos(appId: appId)
            return try restFormat(infos)
        }

        group.get("/app-infos/:appInfoId/localizations") { _, context -> Response in
            guard let appInfoId = context.parameters.get("appInfoId") else { return jsonError("Missing appInfoId") }
            let items = try await self.appInfoRepo.listLocalizations(appInfoId: appInfoId)
            return try restFormat(items)
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
