public struct AppStoreVersionLocalization: Sendable, Equatable, Identifiable {
    public let id: String
    public let locale: String

    public init(id: String, locale: String) {
        self.id = id
        self.locale = locale
    }
}
