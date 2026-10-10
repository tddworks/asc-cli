import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct PerfOverviewGetTests {

    @Test func `should show what regressed, each metric against its goal and the top hotspots for the device type asked for`() async throws {
        let mockRepo = MockPerfOverviewRepository()
        given(mockRepo).getOverview(appId: .value("1234567890"), deviceType: .value("iPhone")).willReturn(
            PerformanceOverview(
                appId: "1234567890",
                deviceType: "iPhone",
                platform: "iOS",
                bundleId: "com.example.app",
                latestVersion: "2.0",
                regressions: [
                    PerformanceInsight(category: .launch, metric: "launchTime", latestVersion: "2.0",
                                       summary: "Launch time increased 20%", isHighImpact: true),
                ],
                metrics: [
                    OverviewMetric(category: "launch", identifier: "launchTime", displayName: "Launch Time",
                                   unit: "s", latestValue: 1.5, latestVersion: "2.0", goalValue: 0.5),
                ],
                hotspots: [
                    PerformanceHotspot(kind: .hangs, signatureId: "sig-1",
                                       signature: "main thread hang in -[UIView layoutSubviews]",
                                       weight: 45.2, count: 12, sourceFile: "MainView.swift", lineNumber: 42,
                                       trend: .up),
                ]
            )
        )

        let cmd = try PerfOverviewGet.parse(["--app-id", "1234567890", "--device-type", "iPhone", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "getPerfOverview" : "asc perf-overview get --app-id 1234567890",
                "listAppMetrics" : "asc perf-metrics list --app-id 1234567890",
                "listBuilds" : "asc builds list --app-id 1234567890"
              },
              "appId" : "1234567890",
              "bundleId" : "com.example.app",
              "deviceType" : "iPhone",
              "hasHighImpactRegressions" : true,
              "hasRegressions" : true,
              "hotspots" : [
                {
                  "count" : 12,
                  "kind" : "HANGS",
                  "lineNumber" : 42,
                  "signature" : "main thread hang in -[UIView layoutSubviews]",
                  "signatureId" : "sig-1",
                  "sourceFile" : "MainView.swift",
                  "trend" : "UP",
                  "weight" : 45.2
                }
              ],
              "id" : "1234567890",
              "latestVersion" : "2.0",
              "metrics" : [
                {
                  "category" : "launch",
                  "displayName" : "Launch Time",
                  "goalValue" : 0.5,
                  "identifier" : "launchTime",
                  "latestValue" : 1.5,
                  "latestVersion" : "2.0",
                  "unit" : "s"
                }
              ],
              "platform" : "iOS",
              "regressions" : [
                {
                  "category" : "LAUNCH",
                  "isHighImpact" : true,
                  "latestVersion" : "2.0",
                  "metric" : "launchTime",
                  "summary" : "Launch time increased 20%"
                }
              ],
              "trendingUp" : [

              ]
            }
          ]
        }
        """)
    }

    @Test func `should show nothing regressed when App Store Connect has no performance data for the app`() async throws {
        let mockRepo = MockPerfOverviewRepository()
        given(mockRepo).getOverview(appId: .value("1234567890"), deviceType: .value(nil)).willReturn(
            PerformanceOverview(appId: "1234567890", platform: "iOS", bundleId: "com.example.app")
        )

        let cmd = try PerfOverviewGet.parse(["--app-id", "1234567890", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "getPerfOverview" : "asc perf-overview get --app-id 1234567890",
                "listAppMetrics" : "asc perf-metrics list --app-id 1234567890",
                "listBuilds" : "asc builds list --app-id 1234567890"
              },
              "appId" : "1234567890",
              "bundleId" : "com.example.app",
              "hasHighImpactRegressions" : false,
              "hasRegressions" : false,
              "hotspots" : [

              ],
              "id" : "1234567890",
              "metrics" : [

              ],
              "platform" : "iOS",
              "regressions" : [

              ],
              "trendingUp" : [

              ]
            }
          ]
        }
        """)
    }
}
