import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct FinanceReportsDownloadTests {

    @Test func `downloads finance report and outputs JSON with row data`() async throws {
        let mockRepo = MockReports()
        given(mockRepo).downloadFinanceReport(
            vendorNumber: .any,
            reportType: .any,
            regionCode: .any,
            reportDate: .any
        ).willReturn([
            ["Region": "US", "Units": "100", "Proceeds": "699.00"]
        ])

        let cmd = try FinanceReportsDownload.parse([
            "--vendor-number", "123",
            "--report-type", "FINANCIAL",
            "--region-code", "US",
            "--report-date", "2024-01",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "Proceeds" : "699.00",
              "Region" : "US",
              "Units" : "100"
            }
          ]
        }
        """)
    }

    @Test func `resolves vendor number from storage when not provided`() async throws {
        let mockRepo = MockReports()
        let mockStorage = MockAuthStorage()
        let accounts = [ConnectAccount(name: "work", keyID: "KEY1", issuerID: "ISS1", isActive: true, vendorNumber: "88012345")]
        given(mockStorage).loadAll().willReturn(accounts)
        given(mockRepo).downloadFinanceReport(
            vendorNumber: .any,
            reportType: .any,
            regionCode: .any,
            reportDate: .any
        ).willReturn([
            ["Region": "US", "Units": "100", "Proceeds": "699.00"]
        ])

        let cmd = try FinanceReportsDownload.parse([
            "--report-type", "FINANCIAL",
            "--region-code", "US",
            "--report-date", "2024-01",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo, storage: mockStorage)

        #expect(output.contains("\"Region\" : \"US\""))
    }

    @Test func `throws when vendor number missing from both flag and storage`() async throws {
        let mockRepo = MockReports()
        let mockStorage = MockAuthStorage()
        given(mockStorage).loadAll().willReturn([])

        let cmd = try FinanceReportsDownload.parse([
            "--report-type", "FINANCIAL",
            "--region-code", "US",
            "--report-date", "2024-01",
        ])

        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo, storage: mockStorage)
        }
    }

    @Test func `table output includes row values`() async throws {
        let mockRepo = MockReports()
        given(mockRepo).downloadFinanceReport(
            vendorNumber: .any,
            reportType: .any,
            regionCode: .any,
            reportDate: .any
        ).willReturn([
            ["Region": "US", "Units": "100", "Proceeds": "699.00"]
        ])

        let cmd = try FinanceReportsDownload.parse([
            "--vendor-number", "123",
            "--report-type", "FINANCIAL",
            "--region-code", "US",
            "--report-date", "2024-01",
            "--output", "table",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("US"))
        #expect(output.contains("100"))
        #expect(output.contains("699.00"))
    }
}
