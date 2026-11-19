import Foundation
import Testing
@testable import ASCKit

@Suite
struct AnalyticsAccessTypeTests {

    @Test func `ONE_TIME_SNAPSHOT has correct raw value`() {
        #expect(AnalyticsAccessType.oneTimeSnapshot.rawValue == "ONE_TIME_SNAPSHOT")
    }

    @Test func `ONGOING has correct raw value`() {
        #expect(AnalyticsAccessType.ongoing.rawValue == "ONGOING")
    }

    @Test func `initializes from CLI argument case-insensitive`() {
        #expect(AnalyticsAccessType(cliArgument: "ONE_TIME_SNAPSHOT") == .oneTimeSnapshot)
        #expect(AnalyticsAccessType(cliArgument: "ongoing") == .ongoing)
        #expect(AnalyticsAccessType(cliArgument: "INVALID") == nil)
    }
}

@Suite
struct AnalyticsCategoryTests {

    @Test func `APP_USAGE has correct raw value`() {
        #expect(AnalyticsCategory.appUsage.rawValue == "APP_USAGE")
    }

    @Test func `APP_STORE_ENGAGEMENT has correct raw value`() {
        #expect(AnalyticsCategory.appStoreEngagement.rawValue == "APP_STORE_ENGAGEMENT")
    }

    @Test func `COMMERCE has correct raw value`() {
        #expect(AnalyticsCategory.commerce.rawValue == "COMMERCE")
    }

    @Test func `FRAMEWORK_USAGE has correct raw value`() {
        #expect(AnalyticsCategory.frameworkUsage.rawValue == "FRAMEWORK_USAGE")
    }

    @Test func `PERFORMANCE has correct raw value`() {
        #expect(AnalyticsCategory.performance.rawValue == "PERFORMANCE")
    }

    @Test func `initializes from CLI argument case-insensitive`() {
        #expect(AnalyticsCategory(cliArgument: "APP_USAGE") == .appUsage)
        #expect(AnalyticsCategory(cliArgument: "commerce") == .commerce)
        #expect(AnalyticsCategory(cliArgument: "INVALID") == nil)
    }
}

@Suite
struct AnalyticsGranularityTests {

    @Test func `DAILY has correct raw value`() {
        #expect(AnalyticsGranularity.daily.rawValue == "DAILY")
    }

    @Test func `WEEKLY has correct raw value`() {
        #expect(AnalyticsGranularity.weekly.rawValue == "WEEKLY")
    }

    @Test func `MONTHLY has correct raw value`() {
        #expect(AnalyticsGranularity.monthly.rawValue == "MONTHLY")
    }

    @Test func `initializes from CLI argument case-insensitive`() {
        #expect(AnalyticsGranularity(cliArgument: "DAILY") == .daily)
        #expect(AnalyticsGranularity(cliArgument: "weekly") == .weekly)
        #expect(AnalyticsGranularity(cliArgument: "INVALID") == nil)
    }
}

@Suite
struct AnalyticsReportRequestTests {

    @Test func `request carries appId`() {
        let req = MockRepositoryFactory.makeAnalyticsReportRequest(id: "req-1", appId: "app-99")
        #expect(req.appId == "app-99")
    }

    @Test func `request carries accessType`() {
        let req = MockRepositoryFactory.makeAnalyticsReportRequest(accessType: .ongoing)
        #expect(req.accessType == .ongoing)
    }

    @Test func `request affordances include listReports`() {
        let req = MockRepositoryFactory.makeAnalyticsReportRequest(id: "req-1")
        #expect(req.affordances["listReports"] == "asc analytics-reports reports --request-id req-1")
    }

    @Test func `request affordances include delete`() {
        let req = MockRepositoryFactory.makeAnalyticsReportRequest(id: "req-1")
        #expect(req.affordances["delete"] == "asc analytics-reports delete --request-id req-1")
    }

    @Test func `request affordances include listRequests`() {
        let req = MockRepositoryFactory.makeAnalyticsReportRequest(id: "req-1", appId: "app-1")
        #expect(req.affordances["listRequests"] == "asc analytics-reports list --app-id app-1")
    }

    @Test func `stopped request includes isStopped true in JSON`() throws {
        let req = MockRepositoryFactory.makeAnalyticsReportRequest(isStoppedDueToInactivity: true)
        let data = try JSONEncoder().encode(req)
        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("\"isStoppedDueToInactivity\":true"))
    }

    @Test func `nil isStoppedDueToInactivity omitted from JSON`() throws {
        let req = MockRepositoryFactory.makeAnalyticsReportRequest(isStoppedDueToInactivity: nil)
        let data = try JSONEncoder().encode(req)
        let json = String(data: data, encoding: .utf8)!
        #expect(!json.contains("isStoppedDueToInactivity"))
    }
}

@Suite
struct AnalyticsReportModelTests {

    @Test func `report carries requestId`() {
        let report = MockRepositoryFactory.makeAnalyticsReport(id: "rpt-1", requestId: "req-99")
        #expect(report.requestId == "req-99")
    }

    @Test func `report carries name and category`() {
        let report = MockRepositoryFactory.makeAnalyticsReport(name: "App Downloads", category: .appStoreEngagement)
        #expect(report.name == "App Downloads")
        #expect(report.category == .appStoreEngagement)
    }

    @Test func `report affordances include listInstances`() {
        let report = MockRepositoryFactory.makeAnalyticsReport(id: "rpt-1")
        #expect(report.affordances["listInstances"] == "asc analytics-reports instances --report-id rpt-1")
    }

    @Test func `report affordances include listReports`() {
        let report = MockRepositoryFactory.makeAnalyticsReport(id: "rpt-1", requestId: "req-1")
        #expect(report.affordances["listReports"] == "asc analytics-reports reports --request-id req-1")
    }

    @Test func `nil name omitted from JSON`() throws {
        let report = MockRepositoryFactory.makeAnalyticsReport(name: nil)
        let data = try JSONEncoder().encode(report)
        let json = String(data: data, encoding: .utf8)!
        #expect(!json.contains("\"name\""))
    }
}

@Suite
struct AnalyticsReportInstanceTests {

    @Test func `instance carries reportId`() {
        let inst = MockRepositoryFactory.makeAnalyticsReportInstance(id: "inst-1", reportId: "rpt-99")
        #expect(inst.reportId == "rpt-99")
    }

    @Test func `instance carries granularity and processingDate`() {
        let inst = MockRepositoryFactory.makeAnalyticsReportInstance(granularity: .weekly, processingDate: "2024-01-15")
        #expect(inst.granularity == .weekly)
        #expect(inst.processingDate == "2024-01-15")
    }

    @Test func `instance affordances include listSegments`() {
        let inst = MockRepositoryFactory.makeAnalyticsReportInstance(id: "inst-1")
        #expect(inst.affordances["listSegments"] == "asc analytics-reports segments --instance-id inst-1")
    }

    @Test func `instance affordances include listInstances`() {
        let inst = MockRepositoryFactory.makeAnalyticsReportInstance(id: "inst-1", reportId: "rpt-1")
        #expect(inst.affordances["listInstances"] == "asc analytics-reports instances --report-id rpt-1")
    }

    @Test func `nil processingDate omitted from JSON`() throws {
        let inst = MockRepositoryFactory.makeAnalyticsReportInstance(processingDate: nil)
        let data = try JSONEncoder().encode(inst)
        let json = String(data: data, encoding: .utf8)!
        #expect(!json.contains("\"processingDate\""))
    }
}

@Suite
struct AnalyticsReportSegmentTests {

    @Test func `segment carries instanceId`() {
        let seg = MockRepositoryFactory.makeAnalyticsReportSegment(id: "seg-1", instanceId: "inst-99")
        #expect(seg.instanceId == "inst-99")
    }

    @Test func `segment carries url and checksum`() {
        let seg = MockRepositoryFactory.makeAnalyticsReportSegment(
            checksum: "abc123",
            sizeInBytes: 1024,
            url: "https://example.com/data.tsv"
        )
        #expect(seg.checksum == "abc123")
        #expect(seg.sizeInBytes == 1024)
        #expect(seg.url == "https://example.com/data.tsv")
    }

    @Test func `segment affordances include listSegments`() {
        let seg = MockRepositoryFactory.makeAnalyticsReportSegment(id: "seg-1", instanceId: "inst-1")
        #expect(seg.affordances["listSegments"] == "asc analytics-reports segments --instance-id inst-1")
    }

    @Test func `nil fields omitted from JSON`() throws {
        let seg = MockRepositoryFactory.makeAnalyticsReportSegment(checksum: nil, sizeInBytes: nil, url: nil)
        let data = try JSONEncoder().encode(seg)
        let json = String(data: data, encoding: .utf8)!
        #expect(!json.contains("\"checksum\""))
        #expect(!json.contains("\"sizeInBytes\""))
        #expect(!json.contains("\"url\""))
    }
}
