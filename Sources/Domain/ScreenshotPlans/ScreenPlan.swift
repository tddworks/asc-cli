import Foundation

public struct ScreenPlan: Sendable, Equatable, Identifiable {
    public var id: String { appId }
    public let appId: String
    public let appName: String
    /// Optional short tagline for the app.
    public let tagline: String
    /// Full App Store description (from AppStoreVersionLocalization). Provides Gemini with
    /// richer context about the app's purpose and target audience during image generation.
    public let appDescription: String?
    public let tone: ScreenTone
    public let colors: ScreenColors
    public let screens: [ScreenConfig]

    public init(
        appId: String,
        appName: String,
        tagline: String,
        appDescription: String? = nil,
        tone: ScreenTone,
        colors: ScreenColors,
        screens: [ScreenConfig]
    ) {
        self.appId = appId
        self.appName = appName
        self.tagline = tagline
        self.appDescription = appDescription
        self.tone = tone
        self.colors = colors
        self.screens = screens
    }
}

extension ScreenPlan: Codable {
    private enum CodingKeys: String, CodingKey {
        case appId, appName, tagline, appDescription, tone, colors, screens
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        appId = try c.decode(String.self, forKey: .appId)
        appName = try c.decode(String.self, forKey: .appName)
        tagline = try c.decode(String.self, forKey: .tagline)
        appDescription = try c.decodeIfPresent(String.self, forKey: .appDescription)
        tone = try c.decode(ScreenTone.self, forKey: .tone)
        colors = try c.decode(ScreenColors.self, forKey: .colors)
        screens = try c.decode([ScreenConfig].self, forKey: .screens)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(appId, forKey: .appId)
        try c.encode(appName, forKey: .appName)
        try c.encode(tagline, forKey: .tagline)
        try c.encodeIfPresent(appDescription, forKey: .appDescription)
        try c.encode(tone, forKey: .tone)
        try c.encode(colors, forKey: .colors)
        try c.encode(screens, forKey: .screens)
    }
}

extension ScreenPlan: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "generate": "asc app-shots generate --plan app-shots-plan.json --gemini-api-key $GEMINI_API_KEY"
        ]
    }
}
