public struct AnalyticsReportInstance: Sendable, Equatable, Identifiable, AffordanceProviding {
    public let id: String
    public let reportId: String
    public let granularity: AnalyticsGranularity?
    public let processingDate: String?

    public init(
        id: String,
        reportId: String,
        granularity: AnalyticsGranularity?,
        processingDate: String?
    ) {
        self.id = id
        self.reportId = reportId
        self.granularity = granularity
        self.processingDate = processingDate
    }

    public var affordances: [String: String] {
        [
            "listSegments": "asc analytics-reports segments --instance-id \(id)",
            "listInstances": "asc analytics-reports instances --report-id \(reportId)",
        ]
    }
}

extension AnalyticsReportInstance: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Granularity", "Processing Date"]
    }
    public var tableRow: [String] {
        [id, granularity?.rawValue ?? "", processingDate ?? ""]
    }
}

extension AnalyticsReportInstance: Codable {
    enum CodingKeys: String, CodingKey {
        case id, reportId, granularity, processingDate
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(reportId, forKey: .reportId)
        try container.encodeIfPresent(granularity, forKey: .granularity)
        try container.encodeIfPresent(processingDate, forKey: .processingDate)
    }
}
