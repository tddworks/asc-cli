@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKPerfMetricsRepositoryTests {

    private func makeXcodeMetrics(
        platform: String = "IOS",
        categoryIdentifier: AppStoreConnect_Swift_SDK.MetricCategory = .launch,
        metricIdentifier: String = "launchTime",
        unitIdentifier: String = "s",
        unitDisplayName: String = "Seconds",
        pointVersion: String = "2.0",
        pointValue: Double = 1.5,
        goalValue: Double = 1.0
    ) -> XcodeMetrics {
        XcodeMetrics(
            version: "1.0",
            insights: nil,
            productData: [
                .init(
                    platform: platform,
                    metricCategories: [
                        .init(
                            identifier: categoryIdentifier,
                            metrics: [
                                .init(
                                    identifier: metricIdentifier,
                                    goalKeys: nil,
                                    unit: .init(identifier: unitIdentifier, displayName: unitDisplayName),
                                    datasets: [
                                        .init(
                                            filterCriteria: nil,
                                            points: [.init(version: pointVersion, value: pointValue)],
                                            recommendedMetricGoal: .init(value: goalValue)
                                        )
                                    ]
                                )
                            ]
                        )
                    ]
                )
            ]
        )
    }

    @Test func `listAppMetrics flattens XcodeMetrics into PerfPowerMetric`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(makeXcodeMetrics())

        let repo = SDKPerfMetricsRepository(client: stub)
        let result = try await repo.listAppMetrics(appId: "app-1", metricType: nil)

        #expect(result.count == 1)
        #expect(result[0].parentId == "app-1")
        #expect(result[0].parentType == .app)
        #expect(result[0].platform == "IOS")
        #expect(result[0].category == PerformanceMetricCategory.launch)
        #expect(result[0].metricIdentifier == "launchTime")
        #expect(result[0].unit == "s")
        #expect(result[0].latestValue == 1.5)
        #expect(result[0].latestVersion == "2.0")
        #expect(result[0].goalValue == 1.0)
    }

    @Test func `listAppMetrics injects appId into each metric`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(makeXcodeMetrics())

        let repo = SDKPerfMetricsRepository(client: stub)
        let result = try await repo.listAppMetrics(appId: "app-42", metricType: nil)

        #expect(result.allSatisfy { $0.parentId == "app-42" })
        #expect(result.allSatisfy { $0.parentType == .app })
    }

    @Test func `listBuildMetrics injects buildId with build parent type`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(makeXcodeMetrics())

        let repo = SDKPerfMetricsRepository(client: stub)
        let result = try await repo.listBuildMetrics(buildId: "build-7", metricType: nil)

        #expect(result.allSatisfy { $0.parentId == "build-7" })
        #expect(result.allSatisfy { $0.parentType == .build })
    }

    @Test func `listAppMetrics generates synthetic id from parent, category, and metric`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(makeXcodeMetrics(
            categoryIdentifier: AppStoreConnect_Swift_SDK.MetricCategory.memory,
            metricIdentifier: "peakMemory"
        ))

        let repo = SDKPerfMetricsRepository(client: stub)
        let result = try await repo.listAppMetrics(appId: "app-1", metricType: nil)

        #expect(result[0].id == "app-1-MEMORY-peakMemory")
    }

    @Test func `listAppMetrics with metricType filter passes through to request`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(makeXcodeMetrics(categoryIdentifier: .hang, metricIdentifier: "hangRate"))

        let repo = SDKPerfMetricsRepository(client: stub)
        let result = try await repo.listAppMetrics(appId: "app-1", metricType: .hang)

        #expect(result.count == 1)
        #expect(result[0].category == .hang)
    }

    @Test func `listBuildMetrics with metricType filter passes through to request`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(makeXcodeMetrics(categoryIdentifier: .disk, metricIdentifier: "diskWrites"))

        let repo = SDKPerfMetricsRepository(client: stub)
        let result = try await repo.listBuildMetrics(buildId: "build-1", metricType: .disk)

        #expect(result.count == 1)
        #expect(result[0].category == .disk)
    }

    @Test func `listAppMetrics maps all seven metric categories`() async throws {
        let categories: [(AppStoreConnect_Swift_SDK.MetricCategory, PerformanceMetricCategory)] = [
            (.hang, .hang), (.launch, .launch), (.memory, .memory),
            (.disk, .disk), (.battery, .battery), (.termination, .termination),
            (.animation, .animation),
        ]
        for (sdkCategory, domainCategory) in categories {
            let stub = StubAPIClient()
            stub.willReturn(makeXcodeMetrics(categoryIdentifier: sdkCategory, metricIdentifier: "test"))

            let repo = SDKPerfMetricsRepository(client: stub)
            let result = try await repo.listAppMetrics(appId: "app-1", metricType: nil)

            #expect(result[0].category == domainCategory)
        }
    }

    @Test func `listAppMetrics skips metrics with nil identifier`() async throws {
        let stub = StubAPIClient()
        let metrics = XcodeMetrics(
            version: "1.0",
            insights: nil,
            productData: [
                .init(
                    platform: "IOS",
                    metricCategories: [
                        .init(
                            identifier: .launch,
                            metrics: [
                                .init(identifier: nil, goalKeys: nil, unit: nil, datasets: nil),
                                .init(identifier: "launchTime", goalKeys: nil, unit: nil, datasets: nil),
                            ]
                        )
                    ]
                )
            ]
        )
        stub.willReturn(metrics)

        let repo = SDKPerfMetricsRepository(client: stub)
        let result = try await repo.listAppMetrics(appId: "app-1", metricType: nil)

        #expect(result.count == 1)
        #expect(result[0].metricIdentifier == "launchTime")
    }

    @Test func `listAppMetrics skips categories with nil identifier`() async throws {
        let stub = StubAPIClient()
        let metrics = XcodeMetrics(
            version: "1.0",
            insights: nil,
            productData: [
                .init(
                    platform: "IOS",
                    metricCategories: [
                        .init(identifier: nil, metrics: [.init(identifier: "test", goalKeys: nil, unit: nil, datasets: nil)])
                    ]
                )
            ]
        )
        stub.willReturn(metrics)

        let repo = SDKPerfMetricsRepository(client: stub)
        let result = try await repo.listAppMetrics(appId: "app-1", metricType: nil)

        #expect(result.isEmpty)
    }

    @Test func `listAppMetrics handles nil datasets gracefully`() async throws {
        let stub = StubAPIClient()
        let metrics = XcodeMetrics(
            version: "1.0",
            insights: nil,
            productData: [
                .init(
                    platform: "IOS",
                    metricCategories: [
                        .init(identifier: .launch, metrics: [
                            .init(identifier: "launchTime", goalKeys: nil, unit: nil, datasets: nil),
                        ])
                    ]
                )
            ]
        )
        stub.willReturn(metrics)

        let repo = SDKPerfMetricsRepository(client: stub)
        let result = try await repo.listAppMetrics(appId: "app-1", metricType: nil)

        #expect(result.count == 1)
        #expect(result[0].latestValue == nil)
        #expect(result[0].latestVersion == nil)
        #expect(result[0].goalValue == nil)
    }

    @Test func `listAppMetrics returns empty when no productData`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(XcodeMetrics(version: "1.0", insights: nil, productData: nil))

        let repo = SDKPerfMetricsRepository(client: stub)
        let result = try await repo.listAppMetrics(appId: "app-1", metricType: nil)

        #expect(result.isEmpty)
    }
}
