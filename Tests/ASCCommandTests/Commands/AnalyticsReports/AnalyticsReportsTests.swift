import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct AnalyticsReportsRequestTests {

    @Test func `creates a one-time snapshot request with affordances`() async throws {
        let mockRepo = MockAnalyticsReportRepository()
        given(mockRepo).createRequest(appId: .any, accessType: .any).willReturn(
            AnalyticsReportRequest(id: "req-1", appId: "app-1", accessType: .oneTimeSnapshot, isStoppedDueToInactivity: nil)
        )

        let cmd = try AnalyticsReportsRequest.parse(["--app-id", "app-1", "--access-type", "ONE_TIME_SNAPSHOT", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "accessType" : "ONE_TIME_SNAPSHOT",
              "affordances" : {
                "delete" : "asc analytics-reports delete --request-id req-1",
                "listReports" : "asc analytics-reports reports --request-id req-1",
                "listRequests" : "asc analytics-reports list --app-id app-1"
              },
              "appId" : "app-1",
              "id" : "req-1"
            }
          ]
        }
        """)
    }
}

@Suite
struct AnalyticsReportsListTests {

    @Test func `lists requests with affordances`() async throws {
        let mockRepo = MockAnalyticsReportRepository()
        given(mockRepo).listRequests(appId: .any, accessType: .any).willReturn([
            AnalyticsReportRequest(id: "req-1", appId: "app-1", accessType: .ongoing, isStoppedDueToInactivity: nil)
        ])

        let cmd = try AnalyticsReportsList.parse(["--app-id", "app-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "accessType" : "ONGOING",
              "affordances" : {
                "delete" : "asc analytics-reports delete --request-id req-1",
                "listReports" : "asc analytics-reports reports --request-id req-1",
                "listRequests" : "asc analytics-reports list --app-id app-1"
              },
              "appId" : "app-1",
              "id" : "req-1"
            }
          ]
        }
        """)
    }
}

@Suite
struct AnalyticsReportsDeleteTests {

    @Test func `accepts global options including pretty`() throws {
        let cmd = try AnalyticsReportsDelete.parse(["--request-id", "req-1", "--pretty"])
        #expect(cmd.globals.pretty == true)
    }

    @Test func `deletes request and outputs confirmation`() async throws {
        let mockRepo = MockAnalyticsReportRepository()
        given(mockRepo).deleteRequest(id: .any).willReturn(())

        let cmd = try AnalyticsReportsDelete.parse(["--request-id", "req-1"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == "Deleted analytics report request req-1")
    }
}

@Suite
struct AnalyticsReportsReportsListTests {

    @Test func `lists reports with affordances`() async throws {
        let mockRepo = MockAnalyticsReportRepository()
        given(mockRepo).listReports(requestId: .any, category: .any).willReturn([
            AnalyticsReport(id: "rpt-1", requestId: "req-1", name: "App Downloads", category: .appStoreEngagement)
        ])

        let cmd = try AnalyticsReportsReportsList.parse(["--request-id", "req-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listInstances" : "asc analytics-reports instances --report-id rpt-1",
                "listReports" : "asc analytics-reports reports --request-id req-1"
              },
              "category" : "APP_STORE_ENGAGEMENT",
              "id" : "rpt-1",
              "name" : "App Downloads",
              "requestId" : "req-1"
            }
          ]
        }
        """)
    }
}

@Suite
struct AnalyticsReportsInstancesListTests {

    @Test func `lists instances with affordances`() async throws {
        let mockRepo = MockAnalyticsReportRepository()
        given(mockRepo).listInstances(reportId: .any, granularity: .any).willReturn([
            AnalyticsReportInstance(id: "inst-1", reportId: "rpt-1", granularity: .daily, processingDate: "2024-01-15")
        ])

        let cmd = try AnalyticsReportsInstancesList.parse(["--report-id", "rpt-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listInstances" : "asc analytics-reports instances --report-id rpt-1",
                "listSegments" : "asc analytics-reports segments --instance-id inst-1"
              },
              "granularity" : "DAILY",
              "id" : "inst-1",
              "processingDate" : "2024-01-15",
              "reportId" : "rpt-1"
            }
          ]
        }
        """)
    }
}

@Suite
struct AnalyticsReportsSegmentsListTests {

    @Test func `lists segments with affordances`() async throws {
        let mockRepo = MockAnalyticsReportRepository()
        given(mockRepo).listSegments(instanceId: .any).willReturn([
            AnalyticsReportSegment(id: "seg-1", instanceId: "inst-1", checksum: "abc123", sizeInBytes: 2048, url: "https://example.com/data.tsv")
        ])

        let cmd = try AnalyticsReportsSegmentsList.parse(["--instance-id", "inst-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == #"""
        {
          "data" : [
            {
              "affordances" : {
                "listSegments" : "asc analytics-reports segments --instance-id inst-1"
              },
              "checksum" : "abc123",
              "id" : "seg-1",
              "instanceId" : "inst-1",
              "sizeInBytes" : 2048,
              "url" : "https:\/\/example.com\/data.tsv"
            }
          ]
        }
        """#)
    }
}
