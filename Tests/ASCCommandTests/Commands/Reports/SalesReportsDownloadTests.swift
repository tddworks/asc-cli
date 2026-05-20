import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct SalesReportsDownloadTests {

    @Test func `downloads sales report and outputs JSON with row data`() async throws {
        let mockRepo = MockReportRepository()
        given(mockRepo).downloadSalesReport(
            vendorNumber: .any,
            reportType: .any,
            subType: .any,
            frequency: .any,
            reportDate: .any,
            version: .any
        ).willReturn([
            ["Provider": "APPLE", "SKU": "com.example", "Units": "10"]
        ])

        let cmd = try SalesReportsDownload.parse([
            "--vendor-number", "123",
            "--report-type", "SALES",
            "--sub-type", "SUMMARY",
            "--frequency", "DAILY",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "Provider" : "APPLE",
              "SKU" : "com.example",
              "Units" : "10"
            }
          ]
        }
        """)
    }

    @Test func `downloads sales report with report date`() async throws {
        let mockRepo = MockReportRepository()
        given(mockRepo).downloadSalesReport(
            vendorNumber: .any,
            reportType: .any,
            subType: .any,
            frequency: .any,
            reportDate: .any,
            version: .any
        ).willReturn([
            ["Provider": "APPLE", "SKU": "com.a", "Units": "5"]
        ])

        let cmd = try SalesReportsDownload.parse([
            "--vendor-number", "123",
            "--report-type", "SALES",
            "--sub-type", "SUMMARY",
            "--frequency", "MONTHLY",
            "--report-date", "2024-01",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "Provider" : "APPLE",
              "SKU" : "com.a",
              "Units" : "5"
            }
          ]
        }
        """)
    }

    @Test func `table output includes row values`() async throws {
        let mockRepo = MockReportRepository()
        given(mockRepo).downloadSalesReport(
            vendorNumber: .any,
            reportType: .any,
            subType: .any,
            frequency: .any,
            reportDate: .any,
            version: .any
        ).willReturn([
            ["Provider": "APPLE", "SKU": "com.example", "Units": "10"]
        ])

        let cmd = try SalesReportsDownload.parse([
            "--vendor-number", "123",
            "--report-type", "SALES",
            "--sub-type", "SUMMARY",
            "--frequency", "DAILY",
            "--output", "table",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("APPLE"))
        #expect(output.contains("com.example"))
        #expect(output.contains("10"))
    }

    @Test func `resolves vendor number from storage when not provided`() async throws {
        let mockRepo = MockReportRepository()
        let mockStorage = MockAuthStorage()
        let accounts = [ConnectAccount(name: "work", keyID: "KEY1", issuerID: "ISS1", isActive: true, vendorNumber: "88012345")]
        given(mockStorage).loadAll().willReturn(accounts)
        given(mockRepo).downloadSalesReport(
            vendorNumber: .any,
            reportType: .any,
            subType: .any,
            frequency: .any,
            reportDate: .any,
            version: .any
        ).willReturn([
            ["Provider": "APPLE", "Units": "1"]
        ])

        let cmd = try SalesReportsDownload.parse([
            "--report-type", "SALES",
            "--sub-type", "SUMMARY",
            "--frequency", "DAILY",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo, storage: mockStorage)

        #expect(output.contains("\"Provider\" : \"APPLE\""))
    }

    @Test func `explicit vendor number overrides stored value`() async throws {
        let mockRepo = MockReportRepository()
        let mockStorage = MockAuthStorage()
        let accounts = [ConnectAccount(name: "work", keyID: "KEY1", issuerID: "ISS1", isActive: true, vendorNumber: "stored")]
        given(mockStorage).loadAll().willReturn(accounts)
        given(mockRepo).downloadSalesReport(
            vendorNumber: .value("explicit"),
            reportType: .any,
            subType: .any,
            frequency: .any,
            reportDate: .any,
            version: .any
        ).willReturn([
            ["Provider": "APPLE", "Units": "1"]
        ])

        let cmd = try SalesReportsDownload.parse([
            "--vendor-number", "explicit",
            "--report-type", "SALES",
            "--sub-type", "SUMMARY",
            "--frequency", "DAILY",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo, storage: mockStorage)

        #expect(output.contains("\"Provider\" : \"APPLE\""))
    }

    @Test func `throws when vendor number missing from both flag and storage`() async throws {
        let mockRepo = MockReportRepository()
        let mockStorage = MockAuthStorage()
        given(mockStorage).loadAll().willReturn([])

        let cmd = try SalesReportsDownload.parse([
            "--report-type", "SALES",
            "--sub-type", "SUMMARY",
            "--frequency", "DAILY",
        ])

        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo, storage: mockStorage)
        }
    }

    @Test func `forwards --version flag to repository as filterVersion`() async throws {
        let mockRepo = MockReportRepository()
        given(mockRepo).downloadSalesReport(
            vendorNumber: .any,
            reportType: .any,
            subType: .any,
            frequency: .any,
            reportDate: .any,
            version: .value("1.4")
        ).willReturn([
            ["Provider": "APPLE", "Units": "16"]
        ])

        let cmd = try SalesReportsDownload.parse([
            "--vendor-number", "123",
            "--report-type", "SALES",
            "--sub-type", "SUMMARY",
            "--frequency", "DAILY",
            "--version", "1.4",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("\"Units\" : \"16\""))
    }

    @Test func `handles empty report`() async throws {
        let mockRepo = MockReportRepository()
        given(mockRepo).downloadSalesReport(
            vendorNumber: .any,
            reportType: .any,
            subType: .any,
            frequency: .any,
            reportDate: .any,
            version: .any
        ).willReturn([])

        let cmd = try SalesReportsDownload.parse([
            "--vendor-number", "123",
            "--report-type", "SALES",
            "--sub-type", "SUMMARY",
            "--frequency", "DAILY",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [

          ]
        }
        """)
    }
}
