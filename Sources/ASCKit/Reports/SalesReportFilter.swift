public enum SalesReportType: String, Sendable, Equatable, Codable, CaseIterable {
    case sales = "SALES"
    case preOrder = "PRE_ORDER"
    case newsstand = "NEWSSTAND"
    case subscription = "SUBSCRIPTION"
    case subscriptionEvent = "SUBSCRIPTION_EVENT"
    case subscriber = "SUBSCRIBER"
    case subscriptionOfferCodeRedemption = "SUBSCRIPTION_OFFER_CODE_REDEMPTION"
    case installs = "INSTALLS"
    case firstAnnual = "FIRST_ANNUAL"
    case winBackEligibility = "WIN_BACK_ELIGIBILITY"

    public init?(cliArgument: String) {
        self.init(rawValue: cliArgument.uppercased())
    }
}

public enum SalesReportSubType: String, Sendable, Equatable, Codable, CaseIterable {
    case summary = "SUMMARY"
    case detailed = "DETAILED"
    case summaryInstallType = "SUMMARY_INSTALL_TYPE"
    case summaryTerritory = "SUMMARY_TERRITORY"
    case summaryChannel = "SUMMARY_CHANNEL"

    public init?(cliArgument: String) {
        self.init(rawValue: cliArgument.uppercased())
    }
}

public enum ReportFrequency: String, Sendable, Equatable, Codable, CaseIterable {
    case daily = "DAILY"
    case weekly = "WEEKLY"
    case monthly = "MONTHLY"
    case yearly = "YEARLY"

    public init?(cliArgument: String) {
        self.init(rawValue: cliArgument.uppercased())
    }
}
