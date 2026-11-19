/// A Product Page Optimization test (ASC API: `appStoreVersionExperiments` v2).
///
/// Tests are app-scoped: each one shows a share of App Store traffic one of up
/// to three treatments instead of the original product page.
public struct AppStoreVersionExperiment: Sendable, Equatable, Identifiable {
    public let id: String
    /// Parent app identifier — injected by Infrastructure
    public let appId: String
    public let name: String
    public let platform: AppStorePlatform
    /// Percentage of users (1–100) shown a treatment instead of the original page.
    public let trafficProportion: Int
    public let state: AppStoreVersionExperimentState
    public let isReviewRequired: Bool
    /// ISO-8601 timestamps. Kept as strings so JSON in/out is lossless.
    public let startDate: String?
    public let endDate: String?
    public let latestControlVersionId: String?

    public init(
        id: String,
        appId: String,
        name: String,
        platform: AppStorePlatform,
        trafficProportion: Int,
        state: AppStoreVersionExperimentState,
        isReviewRequired: Bool = true,
        startDate: String? = nil,
        endDate: String? = nil,
        latestControlVersionId: String? = nil
    ) {
        self.id = id
        self.appId = appId
        self.name = name
        self.platform = platform
        self.trafficProportion = trafficProportion
        self.state = state
        self.isReviewRequired = isReviewRequired
        self.startDate = startDate
        self.endDate = endDate
        self.latestControlVersionId = latestControlVersionId
    }

    /// True while the test is serving traffic: approved, started, and not yet ended.
    public var isRunning: Bool {
        state.isApproved && startDate != nil && endDate == nil
    }

    /// True when App Review has approved the test but it hasn't been started yet.
    public var canStart: Bool {
        state.isApproved && startDate == nil
    }
}

public enum AppStoreVersionExperimentState: String, Sendable, Codable, Equatable, CaseIterable {
    case prepareForSubmission = "PREPARE_FOR_SUBMISSION"
    case readyForReview = "READY_FOR_REVIEW"
    case waitingForReview = "WAITING_FOR_REVIEW"
    case inReview = "IN_REVIEW"
    case accepted = "ACCEPTED"
    case approved = "APPROVED"
    case rejected = "REJECTED"
    case completed = "COMPLETED"
    case stopped = "STOPPED"

    /// The developer can still change the test (name, traffic, treatments) or delete it.
    public var isEditable: Bool {
        self == .prepareForSubmission || self == .readyForReview || self == .rejected
    }
    public var isPendingReview: Bool { self == .waitingForReview || self == .inReview }
    public var isApproved: Bool { self == .accepted || self == .approved }
    public var isFinished: Bool { self == .completed || self == .stopped }
}

extension AppStoreVersionExperiment: Codable {
    enum CodingKeys: String, CodingKey {
        case id, appId, name, platform, trafficProportion, state, isReviewRequired
        case startDate, endDate, latestControlVersionId, isRunning, canStart
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        appId = try c.decode(String.self, forKey: .appId)
        name = try c.decode(String.self, forKey: .name)
        platform = try c.decode(AppStorePlatform.self, forKey: .platform)
        trafficProportion = try c.decode(Int.self, forKey: .trafficProportion)
        state = try c.decode(AppStoreVersionExperimentState.self, forKey: .state)
        isReviewRequired = try c.decode(Bool.self, forKey: .isReviewRequired)
        startDate = try c.decodeIfPresent(String.self, forKey: .startDate)
        endDate = try c.decodeIfPresent(String.self, forKey: .endDate)
        latestControlVersionId = try c.decodeIfPresent(String.self, forKey: .latestControlVersionId)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(appId, forKey: .appId)
        try c.encode(name, forKey: .name)
        try c.encode(platform, forKey: .platform)
        try c.encode(trafficProportion, forKey: .trafficProportion)
        try c.encode(state, forKey: .state)
        try c.encode(isReviewRequired, forKey: .isReviewRequired)
        try c.encodeIfPresent(startDate, forKey: .startDate)
        try c.encodeIfPresent(endDate, forKey: .endDate)
        try c.encodeIfPresent(latestControlVersionId, forKey: .latestControlVersionId)
        try c.encode(isRunning, forKey: .isRunning)
        try c.encode(canStart, forKey: .canStart)
    }
}

extension AppStoreVersionExperiment: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Name", "Platform", "Traffic %", "State", "Started"]
    }
    public var tableRow: [String] {
        [id, name, platform.displayName, String(trafficProportion), state.rawValue, startDate ?? "-"]
    }
}

extension AppStoreVersionExperiment: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        var items: [Affordance] = [
            Affordance(key: "listSiblings", command: "experiments", action: "list", params: ["app-id": appId]),
            Affordance(key: "listTreatments", command: "experiment-treatments", action: "list", params: ["experiment-id": id]),
        ]
        if state.isEditable {
            items.append(Affordance(key: "createTreatment", command: "experiment-treatments", action: "create",
                                    params: ["experiment-id": id, "name": "<name>"]))
            items.append(Affordance(key: "update", command: "experiments", action: "update", params: ["experiment-id": id]))
            items.append(Affordance(key: "delete", command: "experiments", action: "delete", params: ["experiment-id": id]))
        }
        if canStart {
            items.append(Affordance(key: "start", command: "experiments", action: "start", params: ["experiment-id": id]))
        }
        if isRunning {
            items.append(Affordance(key: "stop", command: "experiments", action: "stop", params: ["experiment-id": id]))
        }
        return items
    }
}
