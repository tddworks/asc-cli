public enum AnalyticsAccessType: String, Sendable, Equatable, Codable, CaseIterable {
    case oneTimeSnapshot = "ONE_TIME_SNAPSHOT"
    case ongoing = "ONGOING"

    public init?(cliArgument: String) {
        self.init(rawValue: cliArgument.uppercased())
    }
}

public enum AnalyticsCategory: String, Sendable, Equatable, Codable, CaseIterable {
    case appUsage = "APP_USAGE"
    case appStoreEngagement = "APP_STORE_ENGAGEMENT"
    case commerce = "COMMERCE"
    case frameworkUsage = "FRAMEWORK_USAGE"
    case performance = "PERFORMANCE"

    public init?(cliArgument: String) {
        self.init(rawValue: cliArgument.uppercased())
    }
}

public enum AnalyticsGranularity: String, Sendable, Equatable, Codable, CaseIterable {
    case daily = "DAILY"
    case weekly = "WEEKLY"
    case monthly = "MONTHLY"

    public init?(cliArgument: String) {
        self.init(rawValue: cliArgument.uppercased())
    }
}
