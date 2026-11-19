public enum FinanceReportType: String, Sendable, Equatable, Codable, CaseIterable {
    case financial = "FINANCIAL"
    case financeDetail = "FINANCE_DETAIL"

    public init?(cliArgument: String) {
        self.init(rawValue: cliArgument.uppercased())
    }
}
