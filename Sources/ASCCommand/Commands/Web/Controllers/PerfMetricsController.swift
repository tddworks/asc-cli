import Foundation
import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// `GET /apps/:appId/perf-metrics` and `GET /builds/:buildId/perf-metrics` — power and
/// performance metrics. The `metric-type` query param matches the CLI flag `--metric-type`.
struct PerfMetricsController: Sendable {
    let repo: any PerfMetricsRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/apps/:appId/perf-metrics") { request, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let metrics = try await self.repo.listAppMetrics(appId: appId, metricType: Self.metricType(request))
            return try restFormat(metrics)
        }

        group.get("/builds/:buildId/perf-metrics") { request, context -> Response in
            guard let buildId = context.parameters.get("buildId") else { return jsonError("Missing buildId") }
            let metrics = try await self.repo.listBuildMetrics(buildId: buildId, metricType: Self.metricType(request))
            return try restFormat(metrics)
        }
    }

    private static func metricType(_ request: Request) -> PerformanceMetricCategory? {
        request.uri.queryParameters.get("metric-type").flatMap { PerformanceMetricCategory(rawValue: String($0)) }
    }
}
