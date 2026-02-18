import Mockable

@Mockable
public protocol ScreenshotRepository: Sendable {
    /// List localizations for a specific App Store version (e.g. en-US, zh-Hans).
    func listLocalizations(versionId: String) async throws -> [AppStoreVersionLocalization]

    /// List screenshot sets for a specific localization.
    func listScreenshotSets(localizationId: String) async throws -> [AppScreenshotSet]

    func listScreenshots(setId: String) async throws -> [AppScreenshot]
}
