import Foundation

public enum PerformanceMetricCategory: String, Sendable, Equatable, Codable, CaseIterable {
    case hang = "HANG"
    case launch = "LAUNCH"
    case memory = "MEMORY"
    case disk = "DISK"
    case battery = "BATTERY"
    case termination = "TERMINATION"
    case animation = "ANIMATION"
    case storage = "STORAGE"
}

public enum PerfMetricParentType: String, Sendable, Equatable, Codable {
    case app
    case build
}

public struct PerformanceMetric: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let parentId: String
    public let parentType: PerfMetricParentType
    public let platform: String?
    public let category: PerformanceMetricCategory
    public let metricIdentifier: String
    public let unit: String?
    public let latestValue: Double?
    public let latestVersion: String?
    public let goalValue: Double?

    public init(
        id: String,
        parentId: String,
        parentType: PerfMetricParentType,
        platform: String? = nil,
        category: PerformanceMetricCategory,
        metricIdentifier: String,
        unit: String? = nil,
        latestValue: Double? = nil,
        latestVersion: String? = nil,
        goalValue: Double? = nil
    ) {
        self.id = id
        self.parentId = parentId
        self.parentType = parentType
        self.platform = platform
        self.category = category
        self.metricIdentifier = metricIdentifier
        self.unit = unit
        self.latestValue = latestValue
        self.latestVersion = latestVersion
        self.goalValue = goalValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.parentId = try container.decode(String.self, forKey: .parentId)
        self.parentType = try container.decode(PerfMetricParentType.self, forKey: .parentType)
        self.platform = try container.decodeIfPresent(String.self, forKey: .platform)
        self.category = try container.decode(PerformanceMetricCategory.self, forKey: .category)
        self.metricIdentifier = try container.decode(String.self, forKey: .metricIdentifier)
        self.unit = try container.decodeIfPresent(String.self, forKey: .unit)
        self.latestValue = try container.decodeIfPresent(Double.self, forKey: .latestValue)
        self.latestVersion = try container.decodeIfPresent(String.self, forKey: .latestVersion)
        self.goalValue = try container.decodeIfPresent(Double.self, forKey: .goalValue)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(parentId, forKey: .parentId)
        try container.encode(parentType, forKey: .parentType)
        try container.encodeIfPresent(platform, forKey: .platform)
        try container.encode(category, forKey: .category)
        try container.encode(metricIdentifier, forKey: .metricIdentifier)
        try container.encodeIfPresent(unit, forKey: .unit)
        try container.encodeIfPresent(latestValue, forKey: .latestValue)
        try container.encodeIfPresent(latestVersion, forKey: .latestVersion)
        try container.encodeIfPresent(goalValue, forKey: .goalValue)
    }

    private enum CodingKeys: String, CodingKey {
        case id, parentId, parentType, platform, category, metricIdentifier
        case unit, latestValue, latestVersion, goalValue
    }
}

extension PerformanceMetric: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        switch parentType {
        case .app:
            return [Affordance(key: "listAppMetrics", command: "perf-metrics", action: "list", params: ["app-id": parentId])]
        case .build:
            return [Affordance(key: "listBuildMetrics", command: "perf-metrics", action: "list", params: ["build-id": parentId])]
        }
    }
}

extension PerformanceMetric: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Category", "Metric", "Value", "Unit", "Goal"]
    }

    public var tableRow: [String] {
        [
            id,
            category.rawValue,
            metricIdentifier,
            latestValue.map { String($0) } ?? "-",
            unit ?? "-",
            goalValue.map { String($0) } ?? "-",
        ]
    }
}
