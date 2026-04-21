public struct AppInfo: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    /// Parent app identifier — always present so agents can correlate responses.
    public let appId: String
    /// Legacy lifecycle enum (e.g. `READY_FOR_SALE`, `PREPARE_FOR_SUBMISSION`).
    /// Uses `AppStoreVersionState` values in the ASC API.
    public let appStoreState: String?
    /// Preferred lifecycle enum (e.g. `READY_FOR_DISTRIBUTION`, `PREPARE_FOR_SUBMISSION`).
    public let state: String?
    public let primaryCategoryId: String?
    public let primarySubcategoryOneId: String?
    public let primarySubcategoryTwoId: String?
    public let secondaryCategoryId: String?
    public let secondarySubcategoryOneId: String?
    public let secondarySubcategoryTwoId: String?

    public init(
        id: String,
        appId: String,
        appStoreState: String? = nil,
        state: String? = nil,
        primaryCategoryId: String? = nil,
        primarySubcategoryOneId: String? = nil,
        primarySubcategoryTwoId: String? = nil,
        secondaryCategoryId: String? = nil,
        secondarySubcategoryOneId: String? = nil,
        secondarySubcategoryTwoId: String? = nil
    ) {
        self.id = id
        self.appId = appId
        self.appStoreState = appStoreState
        self.state = state
        self.primaryCategoryId = primaryCategoryId
        self.primarySubcategoryOneId = primarySubcategoryOneId
        self.primarySubcategoryTwoId = primarySubcategoryTwoId
        self.secondaryCategoryId = secondaryCategoryId
        self.secondarySubcategoryOneId = secondarySubcategoryOneId
        self.secondarySubcategoryTwoId = secondarySubcategoryTwoId
    }

    /// True when this app info corresponds to the version currently on sale.
    public var isLive: Bool {
        appStoreState == "READY_FOR_SALE" || state == "READY_FOR_DISTRIBUTION"
    }

    /// True when this app info belongs to a version still in preparation.
    public var isEditable: Bool {
        state == "PREPARE_FOR_SUBMISSION" || appStoreState == "PREPARE_FOR_SUBMISSION"
    }
}

extension AppInfo: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "App ID", "State", "Primary Category", "Secondary Category"]
    }
    public var tableRow: [String] {
        [id, appId, state ?? appStoreState ?? "-", primaryCategoryId ?? "-", secondaryCategoryId ?? "-"]
    }
}

extension AppInfo: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        [
            Affordance(key: "listLocalizations", command: "app-info-localizations", action: "list", params: ["app-info-id": id]),
            Affordance(key: "listAppInfos", command: "app-infos", action: "list", params: ["app-id": appId]),
            Affordance(key: "getAgeRating", command: "age-rating", action: "get", params: ["app-info-id": id]),
            Affordance(key: "updateCategories", command: "app-infos", action: "update", params: ["app-info-id": id]),
        ]
    }
}
