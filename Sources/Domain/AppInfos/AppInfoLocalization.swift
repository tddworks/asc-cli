public struct AppInfoLocalization: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    /// Parent app info identifier — always present so agents can correlate responses.
    public let appInfoId: String
    public let locale: String
    public let name: String?
    public let subtitle: String?
    public let privacyPolicyUrl: String?
    public let privacyChoicesUrl: String?
    public let privacyPolicyText: String?

    public init(
        id: String,
        appInfoId: String,
        locale: String,
        name: String? = nil,
        subtitle: String? = nil,
        privacyPolicyUrl: String? = nil,
        privacyChoicesUrl: String? = nil,
        privacyPolicyText: String? = nil
    ) {
        self.id = id
        self.appInfoId = appInfoId
        self.locale = locale
        self.name = name
        self.subtitle = subtitle
        self.privacyPolicyUrl = privacyPolicyUrl
        self.privacyChoicesUrl = privacyChoicesUrl
        self.privacyPolicyText = privacyPolicyText
    }
}

extension AppInfoLocalization: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "listLocalizations": "asc app-info-localizations list --app-info-id \(appInfoId)",
            "updateLocalization": "asc app-info-localizations update --localization-id \(id)",
        ]
    }
}
