public struct AnalyticsReportSegment: Sendable, Equatable, Identifiable, AffordanceProviding {
    public let id: String
    public let instanceId: String
    public let checksum: String?
    public let sizeInBytes: Int?
    public let url: String?

    public init(
        id: String,
        instanceId: String,
        checksum: String?,
        sizeInBytes: Int?,
        url: String?
    ) {
        self.id = id
        self.instanceId = instanceId
        self.checksum = checksum
        self.sizeInBytes = sizeInBytes
        self.url = url
    }

    public var affordances: [String: String] {
        [
            "listSegments": "asc analytics-reports segments --instance-id \(instanceId)",
        ]
    }
}

extension AnalyticsReportSegment: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Checksum", "Size (bytes)", "URL"]
    }
    public var tableRow: [String] {
        [id, checksum ?? "", sizeInBytes.map { "\($0)" } ?? "", url ?? ""]
    }
}

extension AnalyticsReportSegment: Codable {
    enum CodingKeys: String, CodingKey {
        case id, instanceId, checksum, sizeInBytes, url
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(instanceId, forKey: .instanceId)
        try container.encodeIfPresent(checksum, forKey: .checksum)
        try container.encodeIfPresent(sizeInBytes, forKey: .sizeInBytes)
        try container.encodeIfPresent(url, forKey: .url)
    }
}
