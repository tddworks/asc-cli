import Foundation
import Testing
@testable import Domain

@Suite("DiagnosticLogEntry")
struct DiagnosticLogEntryTests {

    @Test func `log entry carries signature id`() {
        let entry = MockRepositoryFactory.makeDiagnosticLogEntry(
            id: "log-1",
            signatureId: "sig-1",
            bundleId: "com.example.app",
            appVersion: "2.0",
            osVersion: "iOS 17.0",
            deviceType: "iPhone15,2"
        )
        #expect(entry.id == "log-1")
        #expect(entry.signatureId == "sig-1")
        #expect(entry.bundleId == "com.example.app")
        #expect(entry.appVersion == "2.0")
        #expect(entry.osVersion == "iOS 17.0")
        #expect(entry.deviceType == "iPhone15,2")
    }

    @Test func `log entry affordances include list logs for same signature`() {
        let entry = MockRepositoryFactory.makeDiagnosticLogEntry(
            signatureId: "sig-1"
        )
        #expect(entry.affordances["listLogs"] == "asc diagnostic-logs list --signature-id sig-1")
    }

    @Test func `log entry encodes nil fields as omitted`() throws {
        let entry = MockRepositoryFactory.makeDiagnosticLogEntry(
            bundleId: nil,
            appVersion: nil,
            buildVersion: nil,
            osVersion: nil,
            deviceType: nil,
            event: nil,
            callStackSummary: nil
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(entry)
        let json = String(data: data, encoding: .utf8)!
        #expect(!json.contains("bundleId"))
        #expect(!json.contains("appVersion"))
        #expect(!json.contains("callStackSummary"))
    }

    // MARK: - REST

    @Test func `should link a log back to its signature's logs over REST`() {
        let entry = MockRepositoryFactory.makeDiagnosticLogEntry(signatureId: "sig-1")
        #expect(entry.apiLinks == [
            "listLogs": APILink(href: "/api/v1/diagnostics/sig-1/logs", method: "GET"),
        ])
    }

    // MARK: - Table

    @Test func `should show id, bundle id, version, OS, device and event in a table`() {
        let entry = MockRepositoryFactory.makeDiagnosticLogEntry(
            id: "log-1", bundleId: "com.example.app", appVersion: "2.0",
            osVersion: "iOS 17.0", deviceType: "iPhone15,2", event: "hang"
        )
        #expect(DiagnosticLogEntry.tableHeaders == ["ID", "Bundle ID", "Version", "OS", "Device", "Event"])
        #expect(entry.tableRow == ["log-1", "com.example.app", "2.0", "iOS 17.0", "iPhone15,2", "hang"])
    }

    @Test func `should show dashes in a table when a log has no metadata`() {
        let entry = MockRepositoryFactory.makeDiagnosticLogEntry(
            id: "log-1", bundleId: nil, appVersion: nil, osVersion: nil, deviceType: nil, event: nil
        )
        #expect(entry.tableRow == ["log-1", "-", "-", "-", "-", "-"])
    }
}
