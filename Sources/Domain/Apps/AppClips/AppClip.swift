public struct AppClip: Sendable, Equatable, Identifiable {
    public let id: String
    public let appId: String
    public let bundleId: String?

    public init(id: String, appId: String, bundleId: String? = nil) {
        self.id = id
        self.appId = appId
        self.bundleId = bundleId
    }
}

extension AppClip: Codable {
    enum CodingKeys: String, CodingKey {
        case id, appId, bundleId
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        appId = try container.decode(String.self, forKey: .appId)
        bundleId = try container.decodeIfPresent(String.self, forKey: .bundleId)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(appId, forKey: .appId)
        try container.encodeIfPresent(bundleId, forKey: .bundleId)
    }
}

extension AppClip: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "App ID", "Bundle ID"]
    }
    public var tableRow: [String] {
        [id, appId, bundleId ?? ""]
    }
}

extension AppClip: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "listAppClips": "asc app-clips list --app-id \(appId)",
            "listExperiences": "asc app-clip-experiences list --app-clip-id \(id)",
        ]
    }
}
