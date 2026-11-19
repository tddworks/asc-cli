import Foundation

/// The Xcode Organizer overview for an app: what regressed in the latest version,
/// each metric against Apple's goal, and the top hang / launch / disk-write hotspots.
public struct PerformanceOverview: Sendable, Equatable, Identifiable, Codable {
    /// Same as `appId` — there is one overview per app (and device-type filter).
    public let id: String
    /// Parent app identifier — injected by Infrastructure from the request.
    public let appId: String
    /// The device type the overview was narrowed to, when one was requested.
    public let deviceType: String?
    public let platform: String?
    public let bundleId: String?
    public let latestVersion: String?
    /// Metrics that got worse in the latest version.
    public let regressions: [PerformanceInsight]
    /// Metrics trending worse across recent versions.
    public let trendingUp: [PerformanceInsight]
    public let metrics: [OverviewMetric]
    public let hotspots: [PerformanceHotspot]

    public init(
        appId: String,
        deviceType: String? = nil,
        platform: String? = nil,
        bundleId: String? = nil,
        latestVersion: String? = nil,
        regressions: [PerformanceInsight] = [],
        trendingUp: [PerformanceInsight] = [],
        metrics: [OverviewMetric] = [],
        hotspots: [PerformanceHotspot] = []
    ) {
        self.id = appId
        self.appId = appId
        self.deviceType = deviceType
        self.platform = platform
        self.bundleId = bundleId
        self.latestVersion = latestVersion
        self.regressions = regressions
        self.trendingUp = trendingUp
        self.metrics = metrics
        self.hotspots = hotspots
    }

    /// The latest version made at least one metric worse.
    public var hasRegressions: Bool { !regressions.isEmpty }

    /// At least one regression is one Apple marks as high impact.
    public var hasHighImpactRegressions: Bool { regressions.contains(where: \.isHighImpact) }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.appId = try container.decode(String.self, forKey: .appId)
        self.deviceType = try container.decodeIfPresent(String.self, forKey: .deviceType)
        self.platform = try container.decodeIfPresent(String.self, forKey: .platform)
        self.bundleId = try container.decodeIfPresent(String.self, forKey: .bundleId)
        self.latestVersion = try container.decodeIfPresent(String.self, forKey: .latestVersion)
        self.regressions = try container.decode([PerformanceInsight].self, forKey: .regressions)
        self.trendingUp = try container.decode([PerformanceInsight].self, forKey: .trendingUp)
        self.metrics = try container.decode([OverviewMetric].self, forKey: .metrics)
        self.hotspots = try container.decode([PerformanceHotspot].self, forKey: .hotspots)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(appId, forKey: .appId)
        try container.encodeIfPresent(deviceType, forKey: .deviceType)
        try container.encodeIfPresent(platform, forKey: .platform)
        try container.encodeIfPresent(bundleId, forKey: .bundleId)
        try container.encodeIfPresent(latestVersion, forKey: .latestVersion)
        try container.encode(hasRegressions, forKey: .hasRegressions)
        try container.encode(hasHighImpactRegressions, forKey: .hasHighImpactRegressions)
        try container.encode(regressions, forKey: .regressions)
        try container.encode(trendingUp, forKey: .trendingUp)
        try container.encode(metrics, forKey: .metrics)
        try container.encode(hotspots, forKey: .hotspots)
    }

    private enum CodingKeys: String, CodingKey {
        case id, appId, deviceType, platform, bundleId, latestVersion
        case hasRegressions, hasHighImpactRegressions
        case regressions, trendingUp, metrics, hotspots
    }
}

/// A metric Apple flags as regressed or trending worse.
public struct PerformanceInsight: Sendable, Equatable, Codable {
    public let category: PerformanceMetricCategory
    public let metric: String
    public let latestVersion: String?
    /// Apple's one-line summary, e.g. "Launch time increased 20%".
    public let summary: String?
    public let isHighImpact: Bool

    public init(
        category: PerformanceMetricCategory,
        metric: String,
        latestVersion: String? = nil,
        summary: String? = nil,
        isHighImpact: Bool = false
    ) {
        self.category = category
        self.metric = metric
        self.latestVersion = latestVersion
        self.summary = summary
        self.isHighImpact = isHighImpact
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.category = try container.decode(PerformanceMetricCategory.self, forKey: .category)
        self.metric = try container.decode(String.self, forKey: .metric)
        self.latestVersion = try container.decodeIfPresent(String.self, forKey: .latestVersion)
        self.summary = try container.decodeIfPresent(String.self, forKey: .summary)
        self.isHighImpact = try container.decodeIfPresent(Bool.self, forKey: .isHighImpact) ?? false
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(category, forKey: .category)
        try container.encode(metric, forKey: .metric)
        try container.encodeIfPresent(latestVersion, forKey: .latestVersion)
        try container.encodeIfPresent(summary, forKey: .summary)
        try container.encode(isHighImpact, forKey: .isHighImpact)
    }

    private enum CodingKeys: String, CodingKey {
        case category, metric, latestVersion, summary, isHighImpact
    }
}

/// One Xcode Organizer metric: its latest value next to Apple's recommended goal.
public struct OverviewMetric: Sendable, Equatable, Codable {
    public let category: String
    public let identifier: String
    public let displayName: String?
    public let unit: String?
    public let latestValue: Double?
    public let latestVersion: String?
    /// Apple's recommended goal for this metric.
    public let goalValue: Double?

    public init(
        category: String,
        identifier: String,
        displayName: String? = nil,
        unit: String? = nil,
        latestValue: Double? = nil,
        latestVersion: String? = nil,
        goalValue: Double? = nil
    ) {
        self.category = category
        self.identifier = identifier
        self.displayName = displayName
        self.unit = unit
        self.latestValue = latestValue
        self.latestVersion = latestVersion
        self.goalValue = goalValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.category = try container.decode(String.self, forKey: .category)
        self.identifier = try container.decode(String.self, forKey: .identifier)
        self.displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        self.unit = try container.decodeIfPresent(String.self, forKey: .unit)
        self.latestValue = try container.decodeIfPresent(Double.self, forKey: .latestValue)
        self.latestVersion = try container.decodeIfPresent(String.self, forKey: .latestVersion)
        self.goalValue = try container.decodeIfPresent(Double.self, forKey: .goalValue)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(category, forKey: .category)
        try container.encode(identifier, forKey: .identifier)
        try container.encodeIfPresent(displayName, forKey: .displayName)
        try container.encodeIfPresent(unit, forKey: .unit)
        try container.encodeIfPresent(latestValue, forKey: .latestValue)
        try container.encodeIfPresent(latestVersion, forKey: .latestVersion)
        try container.encodeIfPresent(goalValue, forKey: .goalValue)
    }

    private enum CodingKeys: String, CodingKey {
        case category, identifier, displayName, unit, latestValue, latestVersion, goalValue
    }
}

/// A top hang, launch or disk-write call site.
public struct PerformanceHotspot: Sendable, Equatable, Codable {
    public let kind: DiagnosticType
    public let signatureId: String?
    public let signature: String
    /// Share of occurrences (0–100).
    public let weight: Double?
    public let count: Int?
    public let sourceFile: String?
    public let lineNumber: Int?
    public let trend: PerformanceTrend?

    public init(
        kind: DiagnosticType,
        signatureId: String? = nil,
        signature: String,
        weight: Double? = nil,
        count: Int? = nil,
        sourceFile: String? = nil,
        lineNumber: Int? = nil,
        trend: PerformanceTrend? = nil
    ) {
        self.kind = kind
        self.signatureId = signatureId
        self.signature = signature
        self.weight = weight
        self.count = count
        self.sourceFile = sourceFile
        self.lineNumber = lineNumber
        self.trend = trend
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.kind = try container.decode(DiagnosticType.self, forKey: .kind)
        self.signatureId = try container.decodeIfPresent(String.self, forKey: .signatureId)
        self.signature = try container.decode(String.self, forKey: .signature)
        self.weight = try container.decodeIfPresent(Double.self, forKey: .weight)
        self.count = try container.decodeIfPresent(Int.self, forKey: .count)
        self.sourceFile = try container.decodeIfPresent(String.self, forKey: .sourceFile)
        self.lineNumber = try container.decodeIfPresent(Int.self, forKey: .lineNumber)
        self.trend = try container.decodeIfPresent(PerformanceTrend.self, forKey: .trend)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(kind, forKey: .kind)
        try container.encodeIfPresent(signatureId, forKey: .signatureId)
        try container.encode(signature, forKey: .signature)
        try container.encodeIfPresent(weight, forKey: .weight)
        try container.encodeIfPresent(count, forKey: .count)
        try container.encodeIfPresent(sourceFile, forKey: .sourceFile)
        try container.encodeIfPresent(lineNumber, forKey: .lineNumber)
        try container.encodeIfPresent(trend, forKey: .trend)
    }

    private enum CodingKeys: String, CodingKey {
        case kind, signatureId, signature, weight, count, sourceFile, lineNumber, trend
    }
}

/// Which way a hotspot is moving across versions.
public enum PerformanceTrend: String, Sendable, Equatable, Codable, CaseIterable {
    case up = "UP"
    case down = "DOWN"
    case undefined = "UNDEFINED"

    /// The hotspot happens more often than before.
    public var isWorsening: Bool { self == .up }
    /// The hotspot happens less often than before.
    public var isImproving: Bool { self == .down }
}

extension PerformanceOverview: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        [
            Affordance(key: "getPerfOverview", command: "perf-overview", action: "get", params: ["app-id": appId]),
            Affordance(key: "listAppMetrics", command: "perf-metrics", action: "list", params: ["app-id": appId]),
            Affordance(key: "listBuilds", command: "builds", action: "list", params: ["app-id": appId]),
        ]
    }
}

extension PerformanceOverview: Presentable {
    public static var tableHeaders: [String] {
        ["App ID", "Platform", "Latest Version", "Regressions", "High Impact", "Metrics", "Hotspots"]
    }

    public var tableRow: [String] {
        [
            appId,
            platform ?? "-",
            latestVersion ?? "-",
            String(regressions.count),
            String(hasHighImpactRegressions),
            String(metrics.count),
            String(hotspots.count),
        ]
    }
}

extension RESTPathResolver {
    static let _perfOverviewRoutes: Void = {
        registerRoute(command: "perf-overview", parentParam: "app-id", parentSegment: "apps", segment: "perf-overview")
    }()
}
