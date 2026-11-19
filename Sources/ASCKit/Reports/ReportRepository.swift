import Mockable

@Mockable
public protocol ReportRepository: Sendable {
    func downloadSalesReport(
        vendorNumber: String,
        reportType: SalesReportType,
        subType: SalesReportSubType,
        frequency: ReportFrequency,
        reportDate: String?,
        version: String?
    ) async throws -> [[String: String]]

    func downloadFinanceReport(
        vendorNumber: String,
        reportType: FinanceReportType,
        regionCode: String,
        reportDate: String
    ) async throws -> [[String: String]]
}
