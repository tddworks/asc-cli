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

extension AppInfoLocalization: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Locale", "Name", "Subtitle"]
    }
    public var tableRow: [String] {
        [id, locale, name ?? "-", subtitle ?? "-"]
    }
}

extension AppInfoLocalization: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        [
            Affordance(key: "listLocalizations", command: "app-info-localizations", action: "list", params: ["app-info-id": appInfoId]),
            Affordance(key: "updateLocalization", command: "app-info-localizations", action: "update", params: ["localization-id": id]),
            Affordance(key: "delete", command: "app-info-localizations", action: "delete", params: ["localization-id": id]),
        ]
    }
}
