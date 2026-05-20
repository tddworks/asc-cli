import ArgumentParser

struct SalesReportsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "sales-reports",
        abstract: "Download sales and trends reports",
        subcommands: [SalesReportsDownload.self, SalesReportsSummary.self]
    )
}
