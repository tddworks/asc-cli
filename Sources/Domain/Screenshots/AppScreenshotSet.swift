public struct AppScreenshotSet: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public let screenshotDisplayType: ScreenshotDisplayType
    public let screenshotsCount: Int

    public init(
        id: String,
        screenshotDisplayType: ScreenshotDisplayType,
        screenshotsCount: Int = 0
    ) {
        self.id = id
        self.screenshotDisplayType = screenshotDisplayType
        self.screenshotsCount = screenshotsCount
    }

    public var isEmpty: Bool { screenshotsCount == 0 }
    public var deviceCategory: ScreenshotDisplayType.DeviceCategory { screenshotDisplayType.deviceCategory }
    public var displayTypeName: String { screenshotDisplayType.displayName }
}
