public struct AnalyticsReport: Sendable, Equatable, Identifiable, AffordanceProviding {
    public let id: String
    public let requestId: String
    public let name: String?
    public let category: AnalyticsCategory?

    public init(
        id: String,
        requestId: String,
        name: String?,
        category: AnalyticsCategory?
    ) {
        self.id = id
        self.requestId = requestId
        self.name = name
        self.category = category
    }

    public var affordances: [String: String] {
        [
            "listInstances": "asc analytics-reports instances --report-id \(id)",
            "listReports": "asc analytics-reports reports --request-id \(requestId)",
        ]
    }
}

extension AnalyticsReport: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Name", "Category"]
    }
    public var tableRow: [String] {
        [id, name ?? "", category?.rawValue ?? ""]
    }
}

extension AnalyticsReport: Codable {
    enum CodingKeys: String, CodingKey {
        case id, requestId, name, category
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(requestId, forKey: .requestId)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(category, forKey: .category)
    }
}
