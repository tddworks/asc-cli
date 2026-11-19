import Mockable

@Mockable
public protocol PerfOverviews: Sendable {
    func getOverview(appId: String, deviceType: String?) async throws -> PerformanceOverview
}
