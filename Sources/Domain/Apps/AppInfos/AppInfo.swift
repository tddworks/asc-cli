public struct AppInfo: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    /// Parent app identifier — always present so agents can correlate responses.
    public let appId: String
    public let primaryCategoryId: String?
    public let primarySubcategoryOneId: String?
    public let primarySubcategoryTwoId: String?
    public let secondaryCategoryId: String?
    public let secondarySubcategoryOneId: String?
    public let secondarySubcategoryTwoId: String?

    public init(
        id: String,
        appId: String,
        primaryCategoryId: String? = nil,
        primarySubcategoryOneId: String? = nil,
        primarySubcategoryTwoId: String? = nil,
        secondaryCategoryId: String? = nil,
        secondarySubcategoryOneId: String? = nil,
        secondarySubcategoryTwoId: String? = nil
    ) {
        self.id = id
        self.appId = appId
        self.primaryCategoryId = primaryCategoryId
        self.primarySubcategoryOneId = primarySubcategoryOneId
        self.primarySubcategoryTwoId = primarySubcategoryTwoId
        self.secondaryCategoryId = secondaryCategoryId
        self.secondarySubcategoryOneId = secondarySubcategoryOneId
        self.secondarySubcategoryTwoId = secondarySubcategoryTwoId
    }
}

extension AppInfo: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "App ID", "Primary Category", "Secondary Category"]
    }
    public var tableRow: [String] {
        [id, appId, primaryCategoryId ?? "-", secondaryCategoryId ?? "-"]
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
