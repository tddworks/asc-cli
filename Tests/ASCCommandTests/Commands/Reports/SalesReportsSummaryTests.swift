import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct SalesReportsSummaryTests {

    @Test func `aggregates 6 days into a summary with per-currency proceeds`() async throws {
        let mockRepo = MockReportRepository()
        let storage = MockAuthStorage()
        given(storage).loadAll().willReturn([
            ConnectAccount(name: "test", keyID: "K", issuerID: "I", isActive: true, vendorNumber: "123")
        ])

        given(mockRepo).downloadSalesReport(
            vendorNumber: .any, reportType: .any, subType: .any,
            frequency: .any, reportDate: .value("2026-05-13"), version: .any
        ).willReturn([
            row(pti: "1F", units: 7), row(pti: "3F", units: 2), row(pti: "F1", units: 1),
        ])
        given(mockRepo).downloadSalesReport(
            vendorNumber: .any, reportType: .any, subType: .any,
            frequency: .any, reportDate: .value("2026-05-14"), version: .any
        ).willReturn([
            row(pti: "1F", units: 3), row(pti: "3F", units: 1),
        ])
        given(mockRepo).downloadSalesReport(
            vendorNumber: .any, reportType: .any, subType: .any,
            frequency: .any, reportDate: .value("2026-05-15"), version: .any
        ).willReturn([
            row(pti: "1F", units: 8), row(pti: "3F", units: 2),
        ])
        given(mockRepo).downloadSalesReport(
            vendorNumber: .any, reportType: .any, subType: .any,
            frequency: .any, reportDate: .value("2026-05-16"), version: .any
        ).willReturn([
            row(pti: "1F", units: 9), row(pti: "3F", units: 1),
            row(
                pti: "IA1", units: 1,
                sku: "com.onegai.subscriptioncalendar.pass.lifetime",
                customerPrice: "48.00", customerCurrency: "CNY",
                proceeds: "41.94", proceedsCurrency: "USD"
            ),
            row(pti: "IA1", units: 1, sku: "com.onegai.swissboard.pass.lifetime", customerPrice: "0.00"),
        ])
        given(mockRepo).downloadSalesReport(
            vendorNumber: .any, reportType: .any, subType: .any,
            frequency: .any, reportDate: .value("2026-05-17"), version: .any
        ).willReturn([
            row(pti: "1F", units: 16), row(pti: "3F", units: 2),
            row(pti: "7F", units: 1), row(pti: "F1", units: 1),
            row(pti: "IA1", units: 4), row(pti: "IAY", units: 1),
        ])
        given(mockRepo).downloadSalesReport(
            vendorNumber: .any, reportType: .any, subType: .any,
            frequency: .any, reportDate: .value("2026-05-18"), version: .any
        ).willReturn([
            row(pti: "1", units: 2), row(pti: "1F", units: 10), row(pti: "3F", units: 2),
            row(pti: "7F", units: 11), row(pti: "F1", units: 1), row(pti: "IA1", units: 2),
        ])

        let cmd = try SalesReportsSummary.parse([
            "--vendor-number", "123",
            "--from", "2026-05-13",
            "--to", "2026-05-18",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo, storage: storage)

        #expect(output.contains("\"downloads\" : 58"))
        #expect(output.contains("\"payers\" : 1"))
        #expect(output.contains("\"updates\" : 12"))
        #expect(output.contains("\"inAppPurchases\" : 9"))
        #expect(output.contains("\"days\" : 6"))
        #expect(output.contains("\"from\" : \"2026-05-13\""))
        #expect(output.contains("\"to\" : \"2026-05-18\""))
        // Customer Price is per customer-local currency — only paid row was 48.00 CNY
        #expect(output.contains("\"customerSpend\""))
        #expect(output.contains("\"CNY\" : 48"))
        // Developer Proceeds shown in their own currency (USD here for the paid row, 41.94)
        #expect(output.contains("\"proceeds\""))
        #expect(output.contains("\"USD\" : 41.94"))
        // No mention of the legacy misleading single salesUSD scalar
        #expect(!output.contains("\"salesUSD\""))
    }

    @Test func `single day window emits days=1`() async throws {
        let mockRepo = MockReportRepository()
        let storage = MockAuthStorage()
        given(storage).loadAll().willReturn([
            ConnectAccount(name: "test", keyID: "K", issuerID: "I", isActive: true, vendorNumber: "123")
        ])

        given(mockRepo).downloadSalesReport(
            vendorNumber: .any, reportType: .any, subType: .any,
            frequency: .any, reportDate: .value("2026-05-18"), version: .any
        ).willReturn([row(pti: "1F", units: 10)])

        let cmd = try SalesReportsSummary.parse([
            "--vendor-number", "123",
            "--from", "2026-05-18",
            "--to", "2026-05-18",
        ])
        let output = try await cmd.execute(repo: mockRepo, storage: storage)

        #expect(output.contains("\"days\":1"))
        #expect(output.contains("\"downloads\":10"))
    }

    @Test func `--from after --to rejects with validation error`() async throws {
        let mockRepo = MockReportRepository()
        let storage = MockAuthStorage()
        given(storage).loadAll().willReturn([
            ConnectAccount(name: "test", keyID: "K", issuerID: "I", isActive: true, vendorNumber: "123")
        ])

        let cmd = try SalesReportsSummary.parse([
            "--vendor-number", "123",
            "--from", "2026-05-20",
            "--to", "2026-05-13",
        ])

        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo, storage: storage)
        }
    }

    // MARK: - helpers

    private func row(
        pti: String,
        units: Int,
        sku: String = "com.example.app",
        customerPrice: String = "0.00",
        customerCurrency: String = "USD",
        proceeds: String = "0.00",
        proceedsCurrency: String = "USD"
    ) -> [String: String] {
        [
            "Product Type Identifier": pti,
            "Units": "\(units)",
            "SKU": sku,
            "Customer Price": customerPrice,
            "Customer Currency": customerCurrency,
            "Currency of Proceeds": proceedsCurrency,
            "Developer Proceeds": proceeds,
        ]
    }
}

