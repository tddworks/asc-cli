@preconcurrency import AppStoreConnect_Swift_SDK
import Domain
import Foundation

public struct SDKPerfOverviewRepository: PerfOverviewRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func getOverview(appId: String, deviceType: String?) async throws -> Domain.PerformanceOverview {
        // The endpoint returns `application/vnd.apple.xcode-overview+json` as raw Data.
        let request = APIEndpoint.v1.apps.id(appId).performanceOverviews.get(
            filterDeviceType: deviceType.map { [$0] }
        )
        let data = try await client.request(request)
        let overview = try JSONDecoder().decode(XcodeOverview.self, from: data)
        return mapOverview(overview, appId: appId, deviceType: deviceType)
    }

    private func mapOverview(_ overview: XcodeOverview, appId: String, deviceType: String?) -> Domain.PerformanceOverview {
        Domain.PerformanceOverview(
            appId: appId,
            deviceType: deviceType,
            platform: overview.appMetadata?.platform,
            bundleId: overview.appMetadata?.bundleID,
            latestVersion: overview.appMetadata?.latestVersion,
            regressions: (overview.insights?.regressions ?? []).compactMap(mapInsight),
            trendingUp: (overview.insights?.trendingUp ?? []).compactMap(mapInsight),
            metrics: mapMetrics(overview.categories ?? []),
            hotspots: mapHotspots(overview.signatures)
        )
    }

    private func mapInsight(_ insight: MetricsInsight) -> PerformanceInsight? {
        guard let sdkCategory = insight.metricCategory,
              let category = PerformanceMetricCategory(rawValue: sdkCategory.rawValue),
              let metric = insight.metric else { return nil }
        return PerformanceInsight(
            category: category,
            metric: metric,
            latestVersion: insight.latestVersion,
            summary: insight.summaryString,
            isHighImpact: insight.isHighImpact ?? false
        )
    }

    private func mapMetrics(_ categories: [XcodeOverview.Category]) -> [OverviewMetric] {
        categories.flatMap { category -> [OverviewMetric] in
            guard let categoryId = category.identifier else { return [] }
            return (category.sections ?? []).compactMap { section in
                guard let identifier = section.identifier else { return nil }
                let dataset = section.datasets?.first
                let latestPoint = dataset?.points?.last
                return OverviewMetric(
                    category: categoryId,
                    identifier: identifier,
                    displayName: section.displayName,
                    unit: section.unit?.identifier,
                    latestValue: latestPoint?.value,
                    latestVersion: latestPoint?.version,
                    goalValue: dataset?.recommendedMetricGoal?.value
                )
            }
        }
    }

    private func mapHotspots(_ signatures: XcodeOverview.Signatures?) -> [PerformanceHotspot] {
        let groups: [(DiagnosticType, [PerformanceSignature]?)] = [
            (.hangs, signatures?.topHangPoint),
            (.launches, signatures?.topLaunchPoint),
            (.diskWrites, signatures?.topDiskWritePoint),
        ]
        return groups.flatMap { kind, points in
            (points ?? []).compactMap { point -> PerformanceHotspot? in
                guard let signature = point.signature else { return nil }
                return PerformanceHotspot(
                    kind: kind,
                    signatureId: point.signatureID,
                    signature: signature,
                    weight: point.weight,
                    count: point.count,
                    sourceFile: point.sourceFile,
                    lineNumber: point.lineNumber,
                    trend: point.trendInfo.flatMap { PerformanceTrend(rawValue: $0.rawValue) }
                )
            }
        }
    }
}
