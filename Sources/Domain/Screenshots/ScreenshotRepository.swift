import Mockable

@Mockable
public protocol ScreenshotRepository: Sendable {
    /// List screenshot sets for a specific localization ID.
    func listScreenshotSets(localizationId: String) async throws -> [AppScreenshotSet]

    /// List screenshot sets for an app by automatically resolving its first active
    /// App Store version and localization.
    func listScreenshotSets(appId: String) async throws -> [AppScreenshotSet]

    func listScreenshots(setId: String) async throws -> [AppScreenshot]
}
