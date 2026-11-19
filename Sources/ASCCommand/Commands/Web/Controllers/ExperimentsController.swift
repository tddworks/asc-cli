import ASCKit
import Foundation
import Hummingbird
import HummingbirdWebSocket

/// Routes for product page optimization tests (`AppStoreVersionExperiment`),
/// their treatments and treatment localizations.
///
/// Query-param names match the CLI flags: `?state=&limit=`.
struct ExperimentsController: Sendable {
    let repo: any Experiments

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        // MARK: Experiments

        group.get("/apps/:appId/experiments") { request, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let params = request.uri.queryParameters
            var state: AppStoreVersionExperimentState?
            if let raw = params.get("state") {
                guard let parsed = AppStoreVersionExperimentState(rawValue: raw.uppercased()) else {
                    return jsonError("Unknown state '\(raw)'", status: .badRequest)
                }
                state = parsed
            }
            let limit = params.get("limit").flatMap { Int($0) }
            let response = try await self.repo.listExperiments(appId: appId, state: state, limit: limit)
            return try restFormatPaginated(response)
        }

        group.post("/apps/:appId/experiments") { request, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let json = try await Self.jsonBody(request)
            guard let name = json["name"] as? String, !name.isEmpty else {
                return jsonError("Missing name", status: .badRequest)
            }
            guard let trafficProportion = json["trafficProportion"] as? Int, (1...100).contains(trafficProportion) else {
                return jsonError("trafficProportion must be an integer between 1 and 100", status: .badRequest)
            }
            let platformRaw = (json["platform"] as? String) ?? "ios"
            guard let platform = AppStorePlatform(cliArgument: platformRaw) ?? AppStorePlatform(rawValue: platformRaw) else {
                return jsonError("Invalid platform '\(platformRaw)'", status: .badRequest)
            }
            let created = try await self.repo.createExperiment(
                appId: appId, name: name, platform: platform, trafficProportion: trafficProportion
            )
            return try restFormat(created)
        }

        group.get("/experiments/:experimentId") { _, context -> Response in
            guard let experimentId = context.parameters.get("experimentId") else { return jsonError("Missing experimentId") }
            let experiment = try await self.repo.getExperiment(experimentId: experimentId)
            return try restFormat(experiment)
        }

        group.patch("/experiments/:experimentId") { request, context -> Response in
            guard let experimentId = context.parameters.get("experimentId") else { return jsonError("Missing experimentId") }
            let json = try await Self.jsonBody(request)
            let name = json["name"] as? String
            let trafficProportion = json["trafficProportion"] as? Int
            guard name != nil || trafficProportion != nil else {
                return jsonError("Provide at least one of name or trafficProportion", status: .badRequest)
            }
            if let trafficProportion, !(1...100).contains(trafficProportion) {
                return jsonError("trafficProportion must be between 1 and 100", status: .badRequest)
            }
            let updated = try await self.repo.updateExperiment(
                experimentId: experimentId, name: name, trafficProportion: trafficProportion, isStarted: nil
            )
            return try restFormat(updated)
        }

        group.post("/experiments/:experimentId/start") { _, context -> Response in
            guard let experimentId = context.parameters.get("experimentId") else { return jsonError("Missing experimentId") }
            let updated = try await self.repo.updateExperiment(
                experimentId: experimentId, name: nil, trafficProportion: nil, isStarted: true
            )
            return try restFormat(updated)
        }

        group.post("/experiments/:experimentId/stop") { _, context -> Response in
            guard let experimentId = context.parameters.get("experimentId") else { return jsonError("Missing experimentId") }
            let updated = try await self.repo.updateExperiment(
                experimentId: experimentId, name: nil, trafficProportion: nil, isStarted: false
            )
            return try restFormat(updated)
        }

        group.delete("/experiments/:experimentId") { _, context -> Response in
            guard let experimentId = context.parameters.get("experimentId") else { return jsonError("Missing experimentId") }
            try await self.repo.deleteExperiment(experimentId: experimentId)
            return restResponse("{\"deleted\":true}")
        }

        // MARK: Treatments

        group.get("/experiments/:experimentId/experiment-treatments") { request, context -> Response in
            guard let experimentId = context.parameters.get("experimentId") else { return jsonError("Missing experimentId") }
            let limit = request.uri.queryParameters.get("limit").flatMap { Int($0) }
            let response = try await self.repo.listTreatments(experimentId: experimentId, limit: limit)
            return try restFormatPaginated(response)
        }

        group.post("/experiments/:experimentId/experiment-treatments") { request, context -> Response in
            guard let experimentId = context.parameters.get("experimentId") else { return jsonError("Missing experimentId") }
            let json = try await Self.jsonBody(request)
            guard let name = json["name"] as? String, !name.isEmpty else {
                return jsonError("Missing name", status: .badRequest)
            }
            let created = try await self.repo.createTreatment(
                experimentId: experimentId, name: name, appIconName: json["appIconName"] as? String
            )
            return try restFormat(created)
        }

        group.patch("/experiment-treatments/:treatmentId") { request, context -> Response in
            guard let treatmentId = context.parameters.get("treatmentId") else { return jsonError("Missing treatmentId") }
            let json = try await Self.jsonBody(request)
            let name = json["name"] as? String
            let appIconName = json["appIconName"] as? String
            guard name != nil || appIconName != nil else {
                return jsonError("Provide at least one of name or appIconName", status: .badRequest)
            }
            let updated = try await self.repo.updateTreatment(treatmentId: treatmentId, name: name, appIconName: appIconName)
            return try restFormat(updated)
        }

        group.delete("/experiment-treatments/:treatmentId") { _, context -> Response in
            guard let treatmentId = context.parameters.get("treatmentId") else { return jsonError("Missing treatmentId") }
            try await self.repo.deleteTreatment(treatmentId: treatmentId)
            return restResponse("{\"deleted\":true}")
        }

        // MARK: Treatment localizations

        group.get("/experiment-treatments/:treatmentId/experiment-treatment-localizations") { request, context -> Response in
            guard let treatmentId = context.parameters.get("treatmentId") else { return jsonError("Missing treatmentId") }
            let limit = request.uri.queryParameters.get("limit").flatMap { Int($0) }
            let items = try await self.repo.listTreatmentLocalizations(treatmentId: treatmentId, limit: limit)
            return try restFormat(items)
        }

        group.post("/experiment-treatments/:treatmentId/experiment-treatment-localizations") { request, context -> Response in
            guard let treatmentId = context.parameters.get("treatmentId") else { return jsonError("Missing treatmentId") }
            let json = try await Self.jsonBody(request)
            guard let locale = json["locale"] as? String, !locale.isEmpty else {
                return jsonError("Missing locale", status: .badRequest)
            }
            let created = try await self.repo.createTreatmentLocalization(treatmentId: treatmentId, locale: locale)
            return try restFormat(created)
        }

        group.delete("/experiment-treatment-localizations/:localizationId") { _, context -> Response in
            guard let localizationId = context.parameters.get("localizationId") else { return jsonError("Missing localizationId") }
            try await self.repo.deleteTreatmentLocalization(localizationId: localizationId)
            return restResponse("{\"deleted\":true}")
        }
    }

    private static func jsonBody(_ request: Request) async throws -> [String: Any] {
        let body = try await request.body.collect(upTo: 64 * 1024)
        return (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
    }
}
