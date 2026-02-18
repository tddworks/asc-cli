public struct AppScreenshotSet: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    /// Parent localization identifier — always present so agents can correlate responses.
    public let localizationId: String
    public let screenshotDisplayType: ScreenshotDisplayType
    public let screenshotsCount: Int

    public init(
        id: String,
        localizationId: String,
        screenshotDisplayType: ScreenshotDisplayType,
        screenshotsCount: Int = 0
    ) {
        self.id = id
        self.localizationId = localizationId
        self.screenshotDisplayType = screenshotDisplayType
        self.screenshotsCount = screenshotsCount
    }

    public var isEmpty: Bool { screenshotsCount == 0 }
    public var deviceCategory: ScreenshotDisplayType.DeviceCategory { screenshotDisplayType.deviceCategory }
    public var displayTypeName: String { screenshotDisplayType.displayName }
}

extension AppScreenshotSet: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "listScreenshots": "asc screenshots list --set-id \(id)",
            "listScreenshotSets": "asc screenshot-sets list --localization-id \(localizationId)",
        ]
    }
}
