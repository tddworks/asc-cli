import Mockable

@Mockable
public protocol PerfMetrics: Sendable {
    func listAppMetrics(appId: String, metricType: PerformanceMetricCategory?) async throws -> [PerformanceMetric]
    func listBuildMetrics(buildId: String, metricType: PerformanceMetricCategory?) async throws -> [PerformanceMetric]
}
