import ArgumentParser
import Domain
import Hummingbird
import HummingbirdWebSocket
import ASCPlugin
import Infrastructure

/// /api/v1/apps — App and child resource routes.
/// Each route directly delegates to the CLI command's execute() — no middleman.
enum AppsRoutes {
    static func register(on group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/apps") { _, _ -> Response in
            return try await restExec { try await AppsList.parse(["--pretty"]).execute(repo: ClientProvider.makeAppRepository(), affordanceMode: .rest) }
        }

        group.get("/apps/:appId") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            return try await restExec {
                let repo = try ClientProvider.makeAppRepository()
                let app = try await repo.getApp(id: appId)
                let formatter = OutputFormatter(format: .json, pretty: true)
                return try formatter.formatAgentItems([app], headers: [], rowMapper: { _ in [] }, affordanceMode: .rest)
            }
        }

        group.get("/apps/:appId/versions") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            return try await restExec { try await VersionsList.parse(["--app-id", appId, "--pretty"]).execute(repo: ClientProvider.makeVersionRepository(), affordanceMode: .rest) }
        }

        group.get("/apps/:appId/builds") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            return try await restExec { try await BuildsList.parse(["--app-id", appId, "--pretty"]).execute(repo: ClientProvider.makeBuildRepository(), affordanceMode: .rest) }
        }

        group.get("/apps/:appId/testflight") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            return try await restExec { try await BetaGroupsList.parse(["--app-id", appId, "--pretty"]).execute(repo: ClientProvider.makeTestFlightRepository(), affordanceMode: .rest) }
        }

        group.get("/apps/:appId/reviews") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            return try await restExec { try await ReviewsList.parse(["--app-id", appId, "--pretty"]).execute(repo: ClientProvider.makeCustomerReviewRepository(), affordanceMode: .rest) }
        }

        group.get("/apps/:appId/iap") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            return try await restExec { try await IAPList.parse(["--app-id", appId, "--pretty"]).execute(repo: ClientProvider.makeInAppPurchaseRepository(), affordanceMode: .rest) }
        }

        group.get("/apps/:appId/subscription-groups") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            return try await restExec { try await SubscriptionGroupsList.parse(["--app-id", appId, "--pretty"]).execute(repo: ClientProvider.makeSubscriptionGroupRepository(), affordanceMode: .rest) }
        }
    }
}
