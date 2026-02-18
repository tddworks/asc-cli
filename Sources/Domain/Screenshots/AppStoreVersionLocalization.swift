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
