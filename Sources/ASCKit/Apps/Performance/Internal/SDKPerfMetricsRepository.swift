@preconcurrency import AppStoreConnect_Swift_SDK

public struct SDKPerfMetricsRepository: PerfMetricsRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listAppMetrics(appId: String, metricType: PerformanceMetricCategory?) async throws -> [PerformanceMetric] {
        let params = makeAppFilterParams(metricType: metricType)
        let request = APIEndpoint.v1.apps.id(appId).perfPowerMetrics.get(parameters: .init(
            filterMetricType: params
        ))
        let response = try await client.request(request)
        return flattenMetrics(response, parentId: appId, parentType: .app)
    }

    public func listBuildMetrics(buildId: String, metricType: PerformanceMetricCategory?) async throws -> [PerformanceMetric] {
        let params = makeBuildFilterParams(metricType: metricType)
        let request = APIEndpoint.v1.builds.id(buildId).perfPowerMetrics.get(parameters: .init(
            filterMetricType: params
        ))
        let response = try await client.request(request)
        return flattenMetrics(response, parentId: buildId, parentType: .build)
    }

    private func makeAppFilterParams(
        metricType: PerformanceMetricCategory?
    ) -> [APIEndpoint.V1.Apps.WithID.PerfPowerMetrics.GetParameters.FilterMetricType]? {
        guard let metricType else { return nil }
        let mapped: APIEndpoint.V1.Apps.WithID.PerfPowerMetrics.GetParameters.FilterMetricType?
        switch metricType {
        case .disk: mapped = .disk
        case .hang: mapped = .hang
        case .battery: mapped = .battery
        case .launch: mapped = .launch
        case .memory: mapped = .memory
        case .animation: mapped = .animation
        case .termination: mapped = .termination
        case .storage: mapped = .storage
        }
        return mapped.map { [$0] }
    }

    private func makeBuildFilterParams(
        metricType: PerformanceMetricCategory?
    ) -> [APIEndpoint.V1.Builds.WithID.PerfPowerMetrics.GetParameters.FilterMetricType]? {
        guard let metricType else { return nil }
        let mapped: APIEndpoint.V1.Builds.WithID.PerfPowerMetrics.GetParameters.FilterMetricType?
        switch metricType {
        case .disk: mapped = .disk
        case .hang: mapped = .hang
        case .battery: mapped = .battery
        case .launch: mapped = .launch
        case .memory: mapped = .memory
        case .animation: mapped = .animation
        case .termination: mapped = .termination
        case .storage: mapped = .storage
        }
        return mapped.map { [$0] }
    }

    private func flattenMetrics(
        _ xcodeMetrics: XcodeMetrics,
        parentId: String,
        parentType: PerfMetricParentType
    ) -> [PerformanceMetric] {
        guard let productData = xcodeMetrics.productData else { return [] }

        var metrics: [PerformanceMetric] = []
        for product in productData {
            let platform = product.platform
            for category in product.metricCategories ?? [] {
                guard let categoryId = category.identifier else { continue }
                let domainCategory = mapCategory(categoryId)
                for metric in category.metrics ?? [] {
                    guard let metricId = metric.identifier else { continue }
                    let latestPoint = metric.datasets?.first?.points?.last
                    let goal = metric.datasets?.first?.recommendedMetricGoal

                    metrics.append(PerformanceMetric(
                        id: "\(parentId)-\(domainCategory.rawValue)-\(metricId)",
                        parentId: parentId,
                        parentType: parentType,
                        platform: platform,
                        category: domainCategory,
                        metricIdentifier: metricId,
                        unit: metric.unit?.identifier,
                        latestValue: latestPoint?.value,
                        latestVersion: latestPoint?.version,
                        goalValue: goal?.value
                    ))
                }
            }
        }
        return metrics
    }

    private func mapCategory(_ sdk: AppStoreConnect_Swift_SDK.MetricCategory) -> PerformanceMetricCategory {
        switch sdk {
        case .hang: return .hang
        case .launch: return .launch
        case .memory: return .memory
        case .disk: return .disk
        case .battery: return .battery
        case .termination: return .termination
        case .animation: return .animation
        case .storage: return .storage
        }
    }
}
