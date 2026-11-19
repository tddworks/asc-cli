import Mockable

@Mockable
public protocol AnalyticsReportRepository: Sendable {
    func createRequest(appId: String, accessType: AnalyticsAccessType) async throws -> AnalyticsReportRequest
    func listRequests(appId: String, accessType: AnalyticsAccessType?) async throws -> [AnalyticsReportRequest]
    func deleteRequest(id: String) async throws
    func listReports(requestId: String, category: AnalyticsCategory?) async throws -> [AnalyticsReport]
    func listInstances(reportId: String, granularity: AnalyticsGranularity?) async throws -> [AnalyticsReportInstance]
    func listSegments(instanceId: String) async throws -> [AnalyticsReportSegment]
}
