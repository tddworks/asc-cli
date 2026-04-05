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
    let buildRepo: any BuildRepository
    let testFlightRepo: any TestFlightRepository
    let reviewRepo: any CustomerReviewRepository
    let iapRepo: any InAppPurchaseRepository
    let subscriptionGroupRepo: any SubscriptionGroupRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/apps") { _, _ -> Response in
            let apps = try await self.appRepo.listApps(limit: nil).data
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

        group.get("/apps/:appId/builds") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let builds = try await self.buildRepo.listBuilds(appId: appId, platform: nil, version: nil, limit: nil).data
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
    }
}
