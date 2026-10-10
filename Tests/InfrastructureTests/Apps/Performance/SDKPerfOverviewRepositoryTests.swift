import Foundation
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKPerfOverviewRepositoryTests {

    /// A real `GET /v1/apps/{id}/performanceOverviews` body for an app without data (redacted).
    private let emptyOverviewJSON = """
    {"appMetadata": {"appId": "1234567890", "bundleId": "com.example.app", "platform": "iOS"}, "version": "4.0.0", "telemetryIdentifier": "telemetry-1", "categories": [], "insights": {"regressions": [], "trendingUp": []}, "signatures": {"topHangPoint": [], "topLaunchPoint": [], "topDiskWritePoint": []}}
    """

    private let populatedOverviewJSON = """
    {
      "version": "4.0.0",
      "telemetryIdentifier": "telemetry-1",
      "appMetadata": {"appId": "1234567890", "bundleId": "com.example.app", "platform": "iOS", "latestVersion": "2.0"},
      "insights": {
        "regressions": [
          {"metricCategory": "LAUNCH", "metric": "launchTime", "latestVersion": "2.0", "summaryString": "Launch time increased 20%", "highImpact": true},
          {"metricCategory": "HANG", "metric": "hangRate", "latestVersion": "2.0"}
        ],
        "trendingUp": [
          {"metricCategory": "MEMORY", "metric": "peakMemory", "latestVersion": "2.0", "summaryString": "Peak memory is trending up", "highImpact": false}
        ]
      },
      "categories": [
        {
          "identifier": "launch",
          "displayName": "Launch",
          "sections": [
            {
              "identifier": "launchTime",
              "displayName": "Launch Time",
              "unit": {"identifier": "s", "displayName": "Seconds"},
              "datasets": [
                {
                  "points": [{"version": "1.9", "value": 1.2}, {"version": "2.0", "value": 1.5}],
                  "recommendedMetricGoal": {"value": 1.0, "detail": "Apple's goal"}
                },
                {
                  "points": [{"version": "2.0", "value": 9.9}]
                }
              ]
            }
          ]
        }
      ],
      "signatures": {
        "topHangPoint": [
          {"signatureId": "sig-1", "signature": "main thread hang in -[UIView layoutSubviews]", "count": 12, "weight": 45.2, "sourceFile": "MainView.swift", "lineNumber": 42, "trendInfo": "UP"}
        ],
        "topLaunchPoint": [
          {"signatureId": "sig-2", "signature": "dyld start", "weight": 30.0, "trendInfo": "DOWN"}
        ],
        "topDiskWritePoint": [
          {"signature": "sqlite write", "trendInfo": "UNDEFINED"}
        ]
      }
    }
    """

    private func makeRepo(json: String) -> SDKPerfOverviewRepository {
        let stub = StubAPIClient()
        stub.willReturn(Data(json.utf8))
        return SDKPerfOverviewRepository(client: stub)
    }

    @Test func `should show an empty overview when App Store Connect has no performance data for the app`() async throws {
        let overview = try await makeRepo(json: emptyOverviewJSON).getOverview(appId: "1234567890", deviceType: nil)

        #expect(overview == PerformanceOverview(
            appId: "1234567890",
            deviceType: nil,
            platform: "iOS",
            bundleId: "com.example.app",
            latestVersion: nil,
            regressions: [],
            trendingUp: [],
            metrics: [],
            hotspots: []
        ))
    }

    @Test func `should belong to the app it was requested for`() async throws {
        let json = emptyOverviewJSON.replacingOccurrences(of: "\"appId\": \"1234567890\"", with: "\"appId\": \"999\"")

        let overview = try await makeRepo(json: json).getOverview(appId: "1234567890", deviceType: nil)

        #expect(overview.appId == "1234567890")
        #expect(overview.id == "1234567890")
    }

    @Test func `should show which device type the overview was narrowed to`() async throws {
        let overview = try await makeRepo(json: emptyOverviewJSON).getOverview(appId: "1234567890", deviceType: "iPhone")

        #expect(overview.deviceType == "iPhone")
    }

    @Test func `should show the latest version the app shipped`() async throws {
        let overview = try await makeRepo(json: populatedOverviewJSON).getOverview(appId: "1234567890", deviceType: nil)

        #expect(overview.latestVersion == "2.0")
    }

    @Test func `should show what regressed and what is trending worse with Apple's summary and impact`() async throws {
        let overview = try await makeRepo(json: populatedOverviewJSON).getOverview(appId: "1234567890", deviceType: nil)

        #expect(overview.regressions == [
            PerformanceInsight(category: .launch, metric: "launchTime", latestVersion: "2.0",
                               summary: "Launch time increased 20%", isHighImpact: true),
            PerformanceInsight(category: .hang, metric: "hangRate", latestVersion: "2.0",
                               summary: nil, isHighImpact: false),
        ])
        #expect(overview.trendingUp == [
            PerformanceInsight(category: .memory, metric: "peakMemory", latestVersion: "2.0",
                               summary: "Peak memory is trending up", isHighImpact: false),
        ])
        #expect(overview.hasHighImpactRegressions == true)
    }

    @Test func `should show each metric's latest value next to Apple's goal`() async throws {
        let overview = try await makeRepo(json: populatedOverviewJSON).getOverview(appId: "1234567890", deviceType: nil)

        #expect(overview.metrics == [
            OverviewMetric(category: "launch", identifier: "launchTime", displayName: "Launch Time", unit: "s",
                           latestValue: 1.5, latestVersion: "2.0", goalValue: 1.0),
        ])
    }

    @Test func `should list the top hang, launch and disk write hotspots with their trend`() async throws {
        let overview = try await makeRepo(json: populatedOverviewJSON).getOverview(appId: "1234567890", deviceType: nil)

        #expect(overview.hotspots == [
            PerformanceHotspot(kind: .hangs, signatureId: "sig-1", signature: "main thread hang in -[UIView layoutSubviews]",
                               weight: 45.2, count: 12, sourceFile: "MainView.swift", lineNumber: 42, trend: .up),
            PerformanceHotspot(kind: .launches, signatureId: "sig-2", signature: "dyld start",
                               weight: 30.0, count: nil, sourceFile: nil, lineNumber: nil, trend: .down),
            PerformanceHotspot(kind: .diskWrites, signatureId: nil, signature: "sqlite write",
                               weight: nil, count: nil, sourceFile: nil, lineNumber: nil, trend: .undefined),
        ])
    }
}
