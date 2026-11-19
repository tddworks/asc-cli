import Foundation

public struct AnalyticsReportRequest: Sendable, Equatable, Identifiable, AffordanceProviding {
    public let id: String
    public let appId: String
    public let accessType: AnalyticsAccessType
    public let isStoppedDueToInactivity: Bool?

    public init(
        id: String,
        appId: String,
        accessType: AnalyticsAccessType,
        isStoppedDueToInactivity: Bool?
    ) {
        self.id = id
        self.appId = appId
        self.accessType = accessType
        self.isStoppedDueToInactivity = isStoppedDueToInactivity
    }

    public var affordances: [String: String] {
        [
            "listReports": "asc analytics-reports reports --request-id \(id)",
            "delete": "asc analytics-reports delete --request-id \(id)",
            "listRequests": "asc analytics-reports list --app-id \(appId)",
        ]
    }
}

extension AnalyticsReportRequest: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "App ID", "Access Type", "Stopped"]
    }
    public var tableRow: [String] {
        [id, appId, accessType.rawValue, isStoppedDueToInactivity.map { "\($0)" } ?? ""]
    }
}

extension AnalyticsReportRequest: Codable {
    enum CodingKeys: String, CodingKey {
        case id, appId, accessType, isStoppedDueToInactivity
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(appId, forKey: .appId)
        try container.encode(accessType, forKey: .accessType)
        try container.encodeIfPresent(isStoppedDueToInactivity, forKey: .isStoppedDueToInactivity)
    }
}
