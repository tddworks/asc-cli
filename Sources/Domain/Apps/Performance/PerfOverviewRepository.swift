import Mockable

@Mockable
public protocol PerfOverviewRepository: Sendable {
    func getOverview(appId: String, deviceType: String?) async throws -> PerformanceOverview
}
