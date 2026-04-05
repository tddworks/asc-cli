import Domain
import Hummingbird
import HummingbirdWebSocket
import ASCPlugin
import Infrastructure

/// /api/v1/apps — App and child resource routes.
/// Each route calls the repository directly — no CLI command bridging.
enum AppsRoutes {
    static func register(on group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/apps") { _, _ -> Response in
            let apps = try await ClientProvider.makeAppRepository().listApps(limit: nil).data
            return try restFormat(apps)
        }

        group.get("/apps/:appId") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let app = try await ClientProvider.makeAppRepository().getApp(id: appId)
            return try restFormat(app)
        }

        group.get("/apps/:appId/versions") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let versions = try await ClientProvider.makeVersionRepository().listVersions(appId: appId)
            return try restFormat(versions)
        }

        group.get("/apps/:appId/builds") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let builds = try await ClientProvider.makeBuildRepository().listBuilds(appId: appId, platform: nil, version: nil, limit: nil).data
            return try restFormat(builds)
        }

        group.get("/apps/:appId/testflight") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let groups = try await ClientProvider.makeTestFlightRepository().listBetaGroups(appId: appId, limit: nil).data
            return try restFormat(groups)
        }

        group.get("/apps/:appId/reviews") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let reviews = try await ClientProvider.makeCustomerReviewRepository().listReviews(appId: appId)
            return try restFormat(reviews)
        }

        group.get("/apps/:appId/iap") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let iaps = try await ClientProvider.makeInAppPurchaseRepository().listInAppPurchases(appId: appId, limit: nil).data
            return try restFormat(iaps)
        }

        group.get("/apps/:appId/subscription-groups") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let groups = try await ClientProvider.makeSubscriptionGroupRepository().listSubscriptionGroups(appId: appId, limit: nil).data
            return try restFormat(groups)
        }
    }
}
