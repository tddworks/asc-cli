public struct AppStoreVersionLocalization: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    /// Parent version identifier — always present so agents can correlate responses.
    public let versionId: String
    public let locale: String

    public init(id: String, versionId: String, locale: String) {
        self.id = id
        self.versionId = versionId
        self.locale = locale
    }
}

extension AppStoreVersionLocalization: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "listScreenshotSets": "asc screenshot-sets list --localization-id \(id)",
            "listLocalizations": "asc localizations list --version-id \(versionId)",
        ]
    }
}
