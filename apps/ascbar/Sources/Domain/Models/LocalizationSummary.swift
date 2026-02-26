/// A single version localization entry — mapped from `asc version-localizations list` output.
public struct LocalizationSummary: Sendable, Equatable, Identifiable {
    public let id: String
    /// BCP 47 locale code, e.g. "en-US".
    public let locale: String
    /// The What's New text for this locale. Nil when not yet set.
    public let whatsNew: String?
    /// True for the first locale returned by the API (the app's primary locale).
    public let isPrimary: Bool

    public init(id: String, locale: String, whatsNew: String?, isPrimary: Bool) {
        self.id = id
        self.locale = locale
        self.whatsNew = whatsNew
        self.isPrimary = isPrimary
    }
}
