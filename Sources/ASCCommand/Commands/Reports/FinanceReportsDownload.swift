import ArgumentParser
import ASCKit

struct FinanceReportsDownload: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "download",
        abstract: "Download a financial report"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Vendor number (auto-resolved from active account if saved)")
    var vendorNumber: String?

    @Option(name: .long, help: "Report type: FINANCIAL, FINANCE_DETAIL")
    var reportType: String

    @Option(name: .long, help: "Region code (e.g. US, EU, JP)")
    var regionCode: String

    @Option(name: .long, help: "Report date (e.g. 2024-01)")
    var reportDate: String

    func run() async throws {
        let repo = try ClientProvider.makeReportRepository()
        let storage = ClientProvider.makeAuthStorage()
        print(try await execute(repo: repo, storage: storage))
    }

    func execute(repo: any ReportRepository, storage: any AuthStorage = ClientProvider.makeAuthStorage()) async throws -> String {
        let resolvedVendorNumber = try VendorNumberResolver.resolve(explicit: vendorNumber, storage: storage)

        guard let parsedReportType = FinanceReportType(cliArgument: reportType) else {
            throw ValidationError("Invalid report type: \(reportType)")
        }

        let rows = try await repo.downloadFinanceReport(
            vendorNumber: resolvedVendorNumber,
            reportType: parsedReportType,
            regionCode: regionCode,
            reportDate: reportDate
        )

        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try ReportOutputHelper.format(rows: rows, formatter: formatter)
    }
}
