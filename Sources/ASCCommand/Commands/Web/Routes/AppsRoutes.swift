import Hummingbird
import HummingbirdWebSocket
import ASCPlugin
import Infrastructure

/// /api/v1/apps — App management routes.
enum AppsRoutes {
    static func register(on group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/apps") { _, _ -> Response in
            do {
                let repo = try ClientProvider.makeAppRepository()
                let output = try await RESTHandlers.listApps(repo: repo)
                return restResponse(output)
            } catch {
                return jsonError("Failed to list apps: \(error.localizedDescription)", status: .internalServerError)
            }
        }

        group.get("/apps/:appId") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else {
                return jsonError("Missing appId parameter")
            }
            do {
                let repo = try ClientProvider.makeAppRepository()
                let output = try await RESTHandlers.getApp(id: appId, repo: repo)
                return restResponse(output)
            } catch {
                return jsonError("App not found: \(error.localizedDescription)", status: .notFound)
            }
        }

        group.get("/apps/:appId/versions") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else {
                return jsonError("Missing appId parameter")
            }
            do {
                let repo = try ClientProvider.makeVersionRepository()
                let output = try await RESTHandlers.listVersions(appId: appId, repo: repo)
                return restResponse(output)
            } catch {
                return jsonError("Failed to list versions: \(error.localizedDescription)", status: .internalServerError)
            }
        }

        group.get("/apps/:appId/builds") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else {
                return jsonError("Missing appId parameter")
            }
            do {
                let repo = try ClientProvider.makeBuildRepository()
                let output = try await RESTHandlers.listBuilds(appId: appId, repo: repo)
                return restResponse(output)
            } catch {
                return jsonError("Failed to list builds: \(error.localizedDescription)", status: .internalServerError)
            }
        }

        group.get("/apps/:appId/testflight") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else {
                return jsonError("Missing appId parameter")
            }
            do {
                let repo = try ClientProvider.makeTestFlightRepository()
                let output = try await RESTHandlers.listBetaGroups(appId: appId, repo: repo)
                return restResponse(output)
            } catch {
                return jsonError("Failed to list beta groups: \(error.localizedDescription)", status: .internalServerError)
            }
        }

        group.get("/apps/:appId/reviews") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else {
                return jsonError("Missing appId parameter")
            }
            do {
                let repo = try ClientProvider.makeCustomerReviewRepository()
                let output = try await RESTHandlers.listReviews(appId: appId, repo: repo)
                return restResponse(output)
            } catch {
                return jsonError("Failed to list reviews: \(error.localizedDescription)", status: .internalServerError)
            }
        }

        group.get("/apps/:appId/iap") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else {
                return jsonError("Missing appId parameter")
            }
            do {
                let repo = try ClientProvider.makeInAppPurchaseRepository()
                let output = try await RESTHandlers.listIAP(appId: appId, repo: repo)
                return restResponse(output)
            } catch {
                return jsonError("Failed to list IAP: \(error.localizedDescription)", status: .internalServerError)
            }
        }

        group.get("/apps/:appId/subscription-groups") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else {
                return jsonError("Missing appId parameter")
            }
            do {
                let repo = try ClientProvider.makeSubscriptionGroupRepository()
                let output = try await RESTHandlers.listSubscriptionGroups(appId: appId, repo: repo)
                return restResponse(output)
            } catch {
                return jsonError("Failed to list subscription groups: \(error.localizedDescription)", status: .internalServerError)
            }
        }
    }
}
