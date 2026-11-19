@preconcurrency import AppStoreConnect_Swift_SDK
import Foundation
import Testing
@testable import ASCKit

@Suite
struct SDKAnalyticsReportRepositoryCreateRequestTests {

    @Test func `createRequest injects appId from parameter`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AnalyticsReportRequestResponse(
            data: AnalyticsReportRequest(
                type: .analyticsReportRequests,
                id: "req-new",
                attributes: .init(accessType: .oneTimeSnapshot)
            ),
            links: .init(this: "")
        ))

        let repo = SDKAnalyticsReports(client: stub)
        let result = try await repo.createRequest(appId: "app-42", accessType: .oneTimeSnapshot)

        #expect(result.id == "req-new")
        #expect(result.appId == "app-42")
        #expect(result.accessType == .oneTimeSnapshot)
    }
}

@Suite
struct SDKAnalyticsReportRepositoryListRequestsTests {

    @Test func `listRequests injects appId into each request`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AnalyticsReportRequestsResponse(
            data: [
                AnalyticsReportRequest(type: .analyticsReportRequests, id: "req-1", attributes: .init(accessType: .ongoing)),
                AnalyticsReportRequest(type: .analyticsReportRequests, id: "req-2", attributes: .init(accessType: .oneTimeSnapshot)),
            ],
            links: .init(this: "")
        ))

        let repo = SDKAnalyticsReports(client: stub)
        let result = try await repo.listRequests(appId: "app-99", accessType: nil)

        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.appId == "app-99" })
        #expect(result[0].accessType == .ongoing)
    }

    @Test func `listRequests maps isStoppedDueToInactivity`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AnalyticsReportRequestsResponse(
            data: [
                AnalyticsReportRequest(type: .analyticsReportRequests, id: "req-1", attributes: .init(isStoppedDueToInactivity: true)),
            ],
            links: .init(this: "")
        ))

        let repo = SDKAnalyticsReports(client: stub)
        let result = try await repo.listRequests(appId: "app-1", accessType: nil)

        #expect(result[0].isStoppedDueToInactivity == true)
    }
}

@Suite
struct SDKAnalyticsReportRepositoryListReportsTests {

    @Test func `listReports injects requestId into each report`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AnalyticsReportsResponse(
            data: [
                AnalyticsReport(type: .analyticsReports, id: "rpt-1", attributes: .init(name: "Downloads", category: .appStoreEngagement)),
                AnalyticsReport(type: .analyticsReports, id: "rpt-2", attributes: .init(name: "Sessions", category: .appUsage)),
            ],
            links: .init(this: "")
        ))

        let repo = SDKAnalyticsReports(client: stub)
        let result = try await repo.listReports(requestId: "req-42", category: nil)

        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.requestId == "req-42" })
        #expect(result[0].name == "Downloads")
        #expect(result[0].category == .appStoreEngagement)
    }
}

@Suite
struct SDKAnalyticsReportRepositoryListInstancesTests {

    @Test func `listInstances injects reportId into each instance`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AnalyticsReportInstancesResponse(
            data: [
                AnalyticsReportInstance(type: .analyticsReportInstances, id: "inst-1", attributes: .init(granularity: .daily, processingDate: "2024-01-15")),
            ],
            links: .init(this: "")
        ))

        let repo = SDKAnalyticsReports(client: stub)
        let result = try await repo.listInstances(reportId: "rpt-42", granularity: nil)

        #expect(result.count == 1)
        #expect(result[0].reportId == "rpt-42")
        #expect(result[0].granularity == .daily)
        #expect(result[0].processingDate == "2024-01-15")
    }
}

@Suite
struct SDKAnalyticsReportRepositoryListSegmentsTests {

    @Test func `listSegments injects instanceId into each segment`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AnalyticsReportSegmentsResponse(
            data: [
                AnalyticsReportSegment(type: .analyticsReportSegments, id: "seg-1", attributes: .init(checksum: "abc", sizeInBytes: 2048, url: URL(string: "https://example.com/data.tsv"))),
            ],
            links: .init(this: "")
        ))

        let repo = SDKAnalyticsReports(client: stub)
        let result = try await repo.listSegments(instanceId: "inst-42")

        #expect(result.count == 1)
        #expect(result[0].instanceId == "inst-42")
        #expect(result[0].checksum == "abc")
        #expect(result[0].sizeInBytes == 2048)
        #expect(result[0].url == "https://example.com/data.tsv")
    }

    @Test func `listSegments maps nil attributes`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AnalyticsReportSegmentsResponse(
            data: [
                AnalyticsReportSegment(type: .analyticsReportSegments, id: "seg-1"),
            ],
            links: .init(this: "")
        ))

        let repo = SDKAnalyticsReports(client: stub)
        let result = try await repo.listSegments(instanceId: "inst-1")

        #expect(result[0].checksum == nil)
        #expect(result[0].sizeInBytes == nil)
        #expect(result[0].url == nil)
    }
}
