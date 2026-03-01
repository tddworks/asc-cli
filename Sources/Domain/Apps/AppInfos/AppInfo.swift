public struct AppInfo: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    /// Parent app identifier — always present so agents can correlate responses.
    public let appId: String

    public init(id: String, appId: String) {
        self.id = id
        self.appId = appId
    }
}

extension AppInfo: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "listLocalizations": "asc app-info-localizations list --app-info-id \(id)",
            "listAppInfos": "asc app-infos list --app-id \(appId)",
            "getAgeRating": "asc age-rating get --app-info-id \(id)",
        ]
    }
}