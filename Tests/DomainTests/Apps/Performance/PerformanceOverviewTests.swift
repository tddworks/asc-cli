import Foundation
import Testing
@testable import Domain

@Suite("PerformanceOverview")
struct PerformanceOverviewTests {

    // MARK: - Identity

    @Test func `should be identified by the app it summarises`() {
        let overview = MockRepositoryFactory.makePerformanceOverview(appId: "1234567890")
        #expect(overview.id == "1234567890")
        #expect(overview.appId == "1234567890")
    }

    // MARK: - Regressions

    @Test func `should have regressions when the latest version made a metric worse`() {
        let overview = MockRepositoryFactory.makePerformanceOverview(
            regressions: [MockRepositoryFactory.makePerformanceInsight()]
        )
        #expect(overview.hasRegressions == true)
    }

    @Test func `should have no regressions when nothing got worse in the latest version`() {
        let overview = MockRepositoryFactory.makePerformanceOverview(regressions: [])
        #expect(overview.hasRegressions == false)
    }

    @Test func `should have high impact regressions when any regression is high impact`() {
        let overview = MockRepositoryFactory.makePerformanceOverview(regressions: [
            MockRepositoryFactory.makePerformanceInsight(metric: "launchTime", isHighImpact: false),
            MockRepositoryFactory.makePerformanceInsight(category: .hang, metric: "hangRate", isHighImpact: true),
        ])
        #expect(overview.hasHighImpactRegressions == true)
    }

    @Test func `should have no high impact regressions when every regression is minor`() {
        let overview = MockRepositoryFactory.makePerformanceOverview(regressions: [
            MockRepositoryFactory.makePerformanceInsight(isHighImpact: false),
        ])
        #expect(overview.hasHighImpactRegressions == false)
    }

    @Test func `should have no high impact regressions when only trending metrics are high impact`() {
        let overview = MockRepositoryFactory.makePerformanceOverview(
            regressions: [],
            trendingUp: [MockRepositoryFactory.makePerformanceInsight(isHighImpact: true)]
        )
        #expect(overview.hasHighImpactRegressions == false)
    }

    // MARK: - Hotspot trend

    @Test func `should be worsening when a hotspot is trending up`() {
        #expect(PerformanceTrend.up.isWorsening == true)
        #expect(PerformanceTrend.up.isImproving == false)
    }

    @Test func `should be improving when a hotspot is trending down`() {
        #expect(PerformanceTrend.down.isImproving == true)
        #expect(PerformanceTrend.down.isWorsening == false)
    }

    @Test func `should be neither worsening nor improving when the trend is undefined`() {
        #expect(PerformanceTrend.undefined.isWorsening == false)
        #expect(PerformanceTrend.undefined.isImproving == false)
    }

    @Test func `should read trends as App Store Connect writes them`() {
        #expect(PerformanceTrend.up.rawValue == "UP")
        #expect(PerformanceTrend.down.rawValue == "DOWN")
        #expect(PerformanceTrend.undefined.rawValue == "UNDEFINED")
    }

    // MARK: - Affordances

    @Test func `should offer to refresh the overview, open app metrics and list builds on the CLI`() {
        let overview = MockRepositoryFactory.makePerformanceOverview(appId: "1234567890")
        #expect(overview.affordances == [
            "getPerfOverview": "asc perf-overview get --app-id 1234567890",
            "listAppMetrics": "asc perf-metrics list --app-id 1234567890",
            "listBuilds": "asc builds list --app-id 1234567890",
        ])
    }

    @Test func `should link to the overview, app metrics and builds over REST`() {
        let overview = MockRepositoryFactory.makePerformanceOverview(appId: "1234567890")
        #expect(overview.apiLinks["getPerfOverview"]?.href == "/api/v1/apps/1234567890/perf-overview")
        #expect(overview.apiLinks["getPerfOverview"]?.method == "GET")
        #expect(overview.apiLinks["listAppMetrics"]?.href == "/api/v1/apps/1234567890/perf-metrics")
        #expect(overview.apiLinks["listBuilds"]?.href == "/api/v1/apps/1234567890/builds")
    }

    // MARK: - JSON schema

    @Test func `should leave platform, bundle id, latest version and device type out when App Store Connect has none`() throws {
        let overview = MockRepositoryFactory.makePerformanceOverview(
            appId: "1234567890", deviceType: nil, platform: nil, bundleId: nil, latestVersion: nil
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let json = String(decoding: try encoder.encode(overview), as: UTF8.self)
        #expect(json == #"{"appId":"1234567890","hasHighImpactRegressions":false,"hasRegressions":false,"hotspots":[],"id":"1234567890","metrics":[],"regressions":[],"trendingUp":[]}"#)
    }

    @Test func `should read back the same overview it wrote`() throws {
        let overview = MockRepositoryFactory.makePerformanceOverview(
            deviceType: "iPhone",
            regressions: [MockRepositoryFactory.makePerformanceInsight(isHighImpact: true)],
            metrics: [MockRepositoryFactory.makeOverviewMetric()],
            hotspots: [MockRepositoryFactory.makePerformanceHotspot()]
        )
        let decoded = try JSONDecoder().decode(PerformanceOverview.self, from: JSONEncoder().encode(overview))
        #expect(decoded == overview)
    }

    // MARK: - App entry point

    @Test func `should offer the performance overview from an app`() {
        let app = App(id: "1234567890", name: "My App", bundleId: "com.example.app")
        #expect(app.affordances["getPerfOverview"] == "asc perf-overview get --app-id 1234567890")
        #expect(app.apiLinks["getPerfOverview"]?.href == "/api/v1/apps/1234567890/perf-overview")
    }
}
