@preconcurrency import AppStoreConnect_Swift_SDK
import Foundation

public struct SDKAnalyticsReportRepository: AnalyticsReportRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func createRequest(appId: String, accessType: ASCKit.AnalyticsAccessType) async throws -> ASCKit.AnalyticsReportRequest {
        let sdkAccessType: AnalyticsReportRequestCreateRequest.Data.Attributes.AccessType
        switch accessType {
        case .oneTimeSnapshot: sdkAccessType = .oneTimeSnapshot
        case .ongoing: sdkAccessType = .ongoing
        }

        let body = AnalyticsReportRequestCreateRequest(
            data: .init(
                type: .analyticsReportRequests,
                attributes: .init(accessType: sdkAccessType),
                relationships: .init(app: .init(data: .init(type: .apps, id: appId)))
            )
        )
        let response = try await client.request(APIEndpoint.v1.analyticsReportRequests.post(body))
        return mapRequest(response.data, appId: appId)
    }

    public func listRequests(appId: String, accessType: ASCKit.AnalyticsAccessType?) async throws -> [ASCKit.AnalyticsReportRequest] {
        let filterAccessType: [APIEndpoint.V1.Apps.WithID.AnalyticsReportRequests.GetParameters.FilterAccessType]?
        if let accessType {
            switch accessType {
            case .oneTimeSnapshot: filterAccessType = [.oneTimeSnapshot]
            case .ongoing: filterAccessType = [.ongoing]
            }
        } else {
            filterAccessType = nil
        }

        let endpoint = APIEndpoint.v1.apps.id(appId).analyticsReportRequests.get(parameters: .init(
            filterAccessType: filterAccessType
        ))
        let response = try await client.request(endpoint)
        return response.data.map { mapRequest($0, appId: appId) }
    }

    public func deleteRequest(id: String) async throws {
        try await client.request(APIEndpoint.v1.analyticsReportRequests.id(id).delete)
    }

    public func listReports(requestId: String, category: ASCKit.AnalyticsCategory?) async throws -> [ASCKit.AnalyticsReport] {
        let filterCategory: [APIEndpoint.V1.AnalyticsReportRequests.WithID.Reports.GetParameters.FilterCategory]?
        if let category {
            switch category {
            case .appUsage: filterCategory = [.appUsage]
            case .appStoreEngagement: filterCategory = [.appStoreEngagement]
            case .commerce: filterCategory = [.commerce]
            case .frameworkUsage: filterCategory = [.frameworkUsage]
            case .performance: filterCategory = [.performance]
            }
        } else {
            filterCategory = nil
        }

        let endpoint = APIEndpoint.v1.analyticsReportRequests.id(requestId).reports.get(parameters: .init(
            filterCategory: filterCategory
        ))
        let response = try await client.request(endpoint)
        return response.data.map { mapReport($0, requestId: requestId) }
    }

    public func listInstances(reportId: String, granularity: ASCKit.AnalyticsGranularity?) async throws -> [ASCKit.AnalyticsReportInstance] {
        let filterGranularity: [APIEndpoint.V1.AnalyticsReports.WithID.Instances.GetParameters.FilterGranularity]?
        if let granularity {
            switch granularity {
            case .daily: filterGranularity = [.daily]
            case .weekly: filterGranularity = [.weekly]
            case .monthly: filterGranularity = [.monthly]
            }
        } else {
            filterGranularity = nil
        }

        let endpoint = APIEndpoint.v1.analyticsReports.id(reportId).instances.get(parameters: .init(
            filterGranularity: filterGranularity
        ))
        let response = try await client.request(endpoint)
        return response.data.map { mapInstance($0, reportId: reportId) }
    }

    public func listSegments(instanceId: String) async throws -> [ASCKit.AnalyticsReportSegment] {
        let endpoint = APIEndpoint.v1.analyticsReportInstances.id(instanceId).segments.get()
        let response = try await client.request(endpoint)
        return response.data.map { mapSegment($0, instanceId: instanceId) }
    }

    // MARK: - Mappers

    private func mapRequest(
        _ sdk: AppStoreConnect_Swift_SDK.AnalyticsReportRequest,
        appId: String
    ) -> ASCKit.AnalyticsReportRequest {
        let accessType: ASCKit.AnalyticsAccessType
        switch sdk.attributes?.accessType {
        case .ongoing: accessType = .ongoing
        default: accessType = .oneTimeSnapshot
        }
        return ASCKit.AnalyticsReportRequest(
            id: sdk.id,
            appId: appId,
            accessType: accessType,
            isStoppedDueToInactivity: sdk.attributes?.isStoppedDueToInactivity
        )
    }

    private func mapReport(
        _ sdk: AppStoreConnect_Swift_SDK.AnalyticsReport,
        requestId: String
    ) -> ASCKit.AnalyticsReport {
        ASCKit.AnalyticsReport(
            id: sdk.id,
            requestId: requestId,
            name: sdk.attributes?.name,
            category: sdk.attributes?.category.map { mapCategory($0) }
        )
    }

    private func mapCategory(_ sdk: AppStoreConnect_Swift_SDK.AnalyticsReport.Attributes.Category) -> ASCKit.AnalyticsCategory {
        switch sdk {
        case .appUsage: return .appUsage
        case .appStoreEngagement: return .appStoreEngagement
        case .commerce: return .commerce
        case .frameworkUsage: return .frameworkUsage
        case .performance: return .performance
        }
    }

    private func mapInstance(
        _ sdk: AppStoreConnect_Swift_SDK.AnalyticsReportInstance,
        reportId: String
    ) -> ASCKit.AnalyticsReportInstance {
        ASCKit.AnalyticsReportInstance(
            id: sdk.id,
            reportId: reportId,
            granularity: sdk.attributes?.granularity.map { mapGranularity($0) },
            processingDate: sdk.attributes?.processingDate
        )
    }

    private func mapGranularity(_ sdk: AppStoreConnect_Swift_SDK.AnalyticsReportInstance.Attributes.Granularity) -> ASCKit.AnalyticsGranularity {
        switch sdk {
        case .daily: return .daily
        case .weekly: return .weekly
        case .monthly: return .monthly
        }
    }

    private func mapSegment(
        _ sdk: AppStoreConnect_Swift_SDK.AnalyticsReportSegment,
        instanceId: String
    ) -> ASCKit.AnalyticsReportSegment {
        ASCKit.AnalyticsReportSegment(
            id: sdk.id,
            instanceId: instanceId,
            checksum: sdk.attributes?.checksum,
            sizeInBytes: sdk.attributes?.sizeInBytes,
            url: sdk.attributes?.url?.absoluteString
        )
    }
}
