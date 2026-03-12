import Testing
import Mockable
@testable import Domain
@testable import ASCCommand

@Suite
struct PerfMetricsListTests {

    @Test func `listed app metrics show category, value, and affordances`() async throws {
        let mockRepo = MockPerfMetricsRepository()
        given(mockRepo).listAppMetrics(appId: .any, metricType: .any).willReturn([
            PerformanceMetric(
                id: "app-1-LAUNCH-launchTime",
                parentId: "app-1",
                parentType: .app,
                platform: "IOS",
                category: .launch,
                metricIdentifier: "launchTime",
                unit: "s",
                latestValue: 1.5,
                latestVersion: "2.0",
                goalValue: 1.0
            )
        ])
        let cmd = try PerfMetricsList.parse(["--app-id", "app-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)
        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listAppMetrics" : "asc perf-metrics list --app-id app-1"
              },
              "category" : "LAUNCH",
              "goalValue" : 1,
              "id" : "app-1-LAUNCH-launchTime",
              "latestValue" : 1.5,
              "latestVersion" : "2.0",
              "metricIdentifier" : "launchTime",
              "parentId" : "app-1",
              "parentType" : "app",
              "platform" : "IOS",
              "unit" : "s"
            }
          ]
        }
        """)
    }

    @Test func `metric type filter is parsed from CLI argument`() async throws {
        let mockRepo = MockPerfMetricsRepository()
        given(mockRepo).listAppMetrics(appId: .any, metricType: .any).willReturn([])
        let cmd = try PerfMetricsList.parse(["--app-id", "app-1", "--metric-type", "DISK"])
        let output = try await cmd.execute(repo: mockRepo)
        #expect(output.contains("\"data\""))
    }

    @Test func `listed build metrics use build parent type`() async throws {
        let mockRepo = MockPerfMetricsRepository()
        given(mockRepo).listBuildMetrics(buildId: .any, metricType: .any).willReturn([
            PerformanceMetric(
                id: "build-1-HANG-hangRate",
                parentId: "build-1",
                parentType: .build,
                category: .hang,
                metricIdentifier: "hangRate"
            )
        ])
        let cmd = try PerfMetricsList.parse(["--build-id", "build-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)
        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listBuildMetrics" : "asc perf-metrics list --build-id build-1"
              },
              "category" : "HANG",
              "id" : "build-1-HANG-hangRate",
              "metricIdentifier" : "hangRate",
              "parentId" : "build-1",
              "parentType" : "build"
            }
          ]
        }
        """)
    }
}
