import Mockable

@Mockable
public protocol PerfMetricsRepository: Sendable {
    func listAppMetrics(appId: String, metricType: PerformanceMetricCategory?) async throws -> [PerformanceMetric]
    func listBuildMetrics(buildId: String, metricType: PerformanceMetricCategory?) async throws -> [PerformanceMetric]
}
