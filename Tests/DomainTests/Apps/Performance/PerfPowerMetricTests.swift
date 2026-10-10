import Foundation
import Testing
@testable import Domain

@Suite("PerformanceMetric")
struct PerformanceMetricTests {

    @Test func `metric carries parent id and category`() {
        let metric = MockRepositoryFactory.makePerfPowerMetric(
            id: "app-1-LAUNCH-launchTime",
            parentId: "app-1",
            parentType: .app,
            category: .launch,
            metricIdentifier: "launchTime"
        )
        #expect(metric.id == "app-1-LAUNCH-launchTime")
        #expect(metric.parentId == "app-1")
        #expect(metric.parentType == .app)
        #expect(metric.category == .launch)
        #expect(metric.metricIdentifier == "launchTime")
    }

    @Test func `metric with build parent type`() {
        let metric = MockRepositoryFactory.makePerfPowerMetric(
            parentId: "build-1",
            parentType: .build,
            category: .hang
        )
        #expect(metric.parentType == .build)
        #expect(metric.category == .hang)
    }

    @Test func `all metric categories have correct raw values`() {
        #expect(PerformanceMetricCategory.hang.rawValue == "HANG")
        #expect(PerformanceMetricCategory.launch.rawValue == "LAUNCH")
        #expect(PerformanceMetricCategory.memory.rawValue == "MEMORY")
        #expect(PerformanceMetricCategory.disk.rawValue == "DISK")
        #expect(PerformanceMetricCategory.battery.rawValue == "BATTERY")
        #expect(PerformanceMetricCategory.termination.rawValue == "TERMINATION")
        #expect(PerformanceMetricCategory.animation.rawValue == "ANIMATION")
        #expect(PerformanceMetricCategory.storage.rawValue == "STORAGE")
    }

    @Test func `metric affordances for app parent include list app metrics`() {
        let metric = MockRepositoryFactory.makePerfPowerMetric(
            parentId: "app-1",
            parentType: .app
        )
        #expect(metric.affordances["listAppMetrics"] == "asc perf-metrics list --app-id app-1")
        #expect(metric.affordances["listBuildMetrics"] == nil)
    }

    @Test func `metric affordances for build parent include list build metrics`() {
        let metric = MockRepositoryFactory.makePerfPowerMetric(
            parentId: "build-1",
            parentType: .build
        )
        #expect(metric.affordances["listBuildMetrics"] == "asc perf-metrics list --build-id build-1")
        #expect(metric.affordances["listAppMetrics"] == nil)
    }

    @Test func `metric encodes to JSON omitting nil fields`() throws {
        let metric = MockRepositoryFactory.makePerfPowerMetric(
            id: "m-1",
            parentId: "app-1",
            parentType: .app,
            category: .launch,
            metricIdentifier: "launchTime",
            unit: "s",
            latestValue: 1.5,
            latestVersion: "2.0",
            goalValue: 1.0
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(metric)
        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("\"unit\":\"s\""))
        #expect(json.contains("\"latestValue\":1.5"))
        #expect(json.contains("\"goalValue\":1"))
    }

    @Test func `metric with nil optional fields omits them from JSON`() throws {
        let metric = MockRepositoryFactory.makePerfPowerMetric(
            latestValue: nil,
            latestVersion: nil,
            goalValue: nil
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(metric)
        let json = String(data: data, encoding: .utf8)!
        #expect(!json.contains("latestValue"))
        #expect(!json.contains("latestVersion"))
        #expect(!json.contains("goalValue"))
    }

    @Test func `parent type raw values`() {
        #expect(PerfMetricParentType.app.rawValue == "app")
        #expect(PerfMetricParentType.build.rawValue == "build")
    }

    // MARK: - REST

    @Test func `should link app metrics to the app's perf-metrics over REST`() {
        let metric = MockRepositoryFactory.makePerfPowerMetric(parentId: "app-1", parentType: .app)
        #expect(metric.apiLinks == [
            "listAppMetrics": APILink(href: "/api/v1/apps/app-1/perf-metrics", method: "GET"),
        ])
    }

    @Test func `should link build metrics to the build's perf-metrics over REST`() {
        let metric = MockRepositoryFactory.makePerfPowerMetric(parentId: "build-1", parentType: .build)
        #expect(metric.apiLinks == [
            "listBuildMetrics": APILink(href: "/api/v1/builds/build-1/perf-metrics", method: "GET"),
        ])
    }

    // MARK: - Table

    @Test func `should show id, category, metric, value, unit and goal in a table`() {
        let metric = MockRepositoryFactory.makePerfPowerMetric(
            id: "m-1", category: .launch, metricIdentifier: "launchTime", unit: "s", latestValue: 1.5, goalValue: 1.0
        )
        #expect(PerformanceMetric.tableHeaders == ["ID", "Category", "Metric", "Value", "Unit", "Goal"])
        #expect(metric.tableRow == ["m-1", "LAUNCH", "launchTime", "1.5", "s", "1.0"])
    }

    @Test func `should show dashes in a table when a metric has no value, unit or goal`() {
        let metric = MockRepositoryFactory.makePerfPowerMetric(
            id: "m-1", category: .hang, metricIdentifier: "hangRate", unit: nil, latestValue: nil, goalValue: nil
        )
        #expect(metric.tableRow == ["m-1", "HANG", "hangRate", "-", "-", "-"])
    }
}
