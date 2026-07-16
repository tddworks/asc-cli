/// One item attached to a `ReviewSubmission`. Each item points at exactly one
/// reviewable resource — usually an App Store version, but Apple also supports
/// custom product pages, experiments, in-app events, etc. We keep the *type*
/// alongside the id so an agent can fan out to the right `get` command.
///
/// When the parent submission's state is `UNRESOLVED_ISSUES`, the rejected
/// item's `state == .rejected` is the API's signal of *which* resource Apple
/// flagged. The reviewer's free-text reasoning lives only in the App Store
/// Connect Resolution Center web UI.
public struct ReviewSubmissionItem: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    /// Parent submission identifier — always present so agents can correlate responses.
    public let submissionId: String
    public let state: ReviewSubmissionItemState
    /// The reviewable resource this item points at (e.g. version id). Apple may
    /// return an item without a relationship payload — keep this optional.
    public let linkedResourceId: String?
    public let linkedResourceType: ReviewSubmissionItemLinkedResource?

    public init(
        id: String,
        submissionId: String,
        state: ReviewSubmissionItemState,
        linkedResourceId: String? = nil,
        linkedResourceType: ReviewSubmissionItemLinkedResource? = nil
    ) {
        self.id = id
        self.submissionId = submissionId
        self.state = state
        self.linkedResourceId = linkedResourceId
        self.linkedResourceType = linkedResourceType
    }

    public var isRejected: Bool { state.isRejected }
    public var isApproved: Bool { state.isApproved }
    public var isPending: Bool { state.isPending }
}

// MARK: - Codable (omit nil optional fields from JSON output)

extension ReviewSubmissionItem {
    enum CodingKeys: String, CodingKey {
        case id, submissionId, state, linkedResourceId, linkedResourceType
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        submissionId = try c.decode(String.self, forKey: .submissionId)
        state = try c.decode(ReviewSubmissionItemState.self, forKey: .state)
        linkedResourceId = try c.decodeIfPresent(String.self, forKey: .linkedResourceId)
        linkedResourceType = try c.decodeIfPresent(ReviewSubmissionItemLinkedResource.self, forKey: .linkedResourceType)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(submissionId, forKey: .submissionId)
        try c.encode(state, forKey: .state)
        try c.encodeIfPresent(linkedResourceId, forKey: .linkedResourceId)
        try c.encodeIfPresent(linkedResourceType, forKey: .linkedResourceType)
    }
}

extension ReviewSubmissionItem: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Submission ID", "State", "Linked Type", "Linked ID"]
    }
    public var tableRow: [String] {
        [id, submissionId, state.rawValue, linkedResourceType?.rawValue ?? "-", linkedResourceId ?? "-"]
    }
}

extension ReviewSubmissionItem: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        var items: [Affordance] = [
            Affordance(key: "getSubmission", command: "review-submissions", action: "get",
                       params: ["submission-id": submissionId]),
            Affordance(key: "listSiblings", command: "review-submissions items", action: "list",
                       params: ["submission-id": submissionId]),
        ]
        if isRejected {
            // The reviewer's message text lives only behind the iris (cookie-auth)
            // surface — the official API has no resolutionCenter endpoints.
            items.append(Affordance(key: "getResolutionDetails", command: "iris resolution-center", action: "get",
                                    params: ["submission-id": submissionId]))
        }
        if let linkedId = linkedResourceId, let linkedType = linkedResourceType {
            switch linkedType {
            case .appStoreVersion:
                items.append(Affordance(key: "getVersion", command: "versions", action: "get",
                                        params: ["version-id": linkedId]))
            case .appCustomProductPageVersion, .appStoreVersionExperiment, .appEvent,
                 .backgroundAssetVersion, .gameCenterAchievementVersion, .gameCenterActivityVersion,
                 .gameCenterChallengeVersion, .gameCenterLeaderboardSetVersion, .gameCenterLeaderboardVersion:
                // Other resource types don't have a top-level `asc <thing> get` yet.
                break
            }
        }
        return items
    }
}

/// The type of the resource an item points at. We keep the cases we currently
/// understand and let the SDK reject unknown ones at decode time — Apple adds
/// new reviewable resource kinds occasionally.
public enum ReviewSubmissionItemLinkedResource: String, Sendable, Equatable, Codable, CaseIterable {
    case appStoreVersion = "APP_STORE_VERSION"
    case appCustomProductPageVersion = "APP_CUSTOM_PRODUCT_PAGE_VERSION"
    case appStoreVersionExperiment = "APP_STORE_VERSION_EXPERIMENT"
    case appEvent = "APP_EVENT"
    case backgroundAssetVersion = "BACKGROUND_ASSET_VERSION"
    case gameCenterAchievementVersion = "GAME_CENTER_ACHIEVEMENT_VERSION"
    case gameCenterActivityVersion = "GAME_CENTER_ACTIVITY_VERSION"
    case gameCenterChallengeVersion = "GAME_CENTER_CHALLENGE_VERSION"
    case gameCenterLeaderboardSetVersion = "GAME_CENTER_LEADERBOARD_SET_VERSION"
    case gameCenterLeaderboardVersion = "GAME_CENTER_LEADERBOARD_VERSION"
}
