import ArgumentParser
import Domain
import Infrastructure

struct SalesReportsDownload: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "download",
        abstract: "Download a sales report"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Vendor number (auto-resolved from active account if saved)")
    var vendorNumber: String?

    @Option(name: .long, help: "Report type: SALES, PRE_ORDER, SUBSCRIPTION, etc.")
    var reportType: String

    @Option(name: .long, help: "Report sub-type: SUMMARY, DETAILED, etc.")
    var subType: String

    @Option(name: .long, help: "Frequency: DAILY, WEEKLY, MONTHLY, YEARLY")
    var frequency: String

    @Option(name: .long, help: "Report date (e.g. 2024-01-15)")
    var reportDate: String?

    @Option(name: .long, help: "Report schema version (e.g. 1_4 for SALES/SUMMARY/DAILY). Omit to use Apple's default.")
    var version: String?

    func run() async throws {
        let repo = try ClientProvider.makeReportRepository()
        let storage = FileAuthStorage()
        print(try await execute(repo: repo, storage: storage))
    }

    func execute(repo: any ReportRepository, storage: any AuthStorage = FileAuthStorage()) async throws -> String {
        let resolvedVendorNumber = try VendorNumberResolver.resolve(explicit: vendorNumber, storage: storage)

        guard let parsedReportType = SalesReportType(cliArgument: reportType) else {
            throw ValidationError("Invalid report type: \(reportType)")
        }
        guard let parsedSubType = SalesReportSubType(cliArgument: subType) else {
            throw ValidationError("Invalid sub-type: \(subType)")
        }
        guard let parsedFrequency = ReportFrequency(cliArgument: frequency) else {
            throw ValidationError("Invalid frequency: \(frequency)")
        }

        let rows = try await repo.downloadSalesReport(
            vendorNumber: resolvedVendorNumber,
            reportType: parsedReportType,
            subType: parsedSubType,
            frequency: parsedFrequency,
            reportDate: reportDate,
            version: version
        )

        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try ReportOutputHelper.format(rows: rows, formatter: formatter)
    }
}
