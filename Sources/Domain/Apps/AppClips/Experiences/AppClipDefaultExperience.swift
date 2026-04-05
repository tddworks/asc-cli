public enum AppClipAction: String, Sendable, Equatable, Codable, CaseIterable {
    case open = "OPEN"
    case view = "VIEW"
    case play = "PLAY"
}

public struct AppClipDefaultExperience: Sendable, Equatable, Identifiable {
    public let id: String
    public let appClipId: String
    public let action: AppClipAction?

    public init(id: String, appClipId: String, action: AppClipAction? = nil) {
        self.id = id
        self.appClipId = appClipId
        self.action = action
    }
}

extension AppClipDefaultExperience: Codable {
    enum CodingKeys: String, CodingKey {
        case id, appClipId, action
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        appClipId = try container.decode(String.self, forKey: .appClipId)
        action = try container.decodeIfPresent(AppClipAction.self, forKey: .action)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(action, forKey: .action)
        try container.encode(id, forKey: .id)
        try container.encode(appClipId, forKey: .appClipId)
    }
}

extension AppClipDefaultExperience: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "App Clip ID", "Action"]
    }
    public var tableRow: [String] {
        [id, appClipId, action?.rawValue ?? ""]
    }
}

extension AppClipDefaultExperience: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "delete": "asc app-clip-experiences delete --experience-id \(id)",
            "listExperiences": "asc app-clip-experiences list --app-clip-id \(appClipId)",
            "listLocalizations": "asc app-clip-experience-localizations list --experience-id \(id)",
        ]
    }
}
