import Foundation
import Mockable

@Mockable
public protocol ScreenshotRepository: Sendable {
    /// List localizations for a specific App Store version (e.g. en-US, zh-Hans).
    func listLocalizations(versionId: String) async throws -> [AppStoreVersionLocalization]

    /// List screenshot sets for a specific localization.
    func listScreenshotSets(localizationId: String) async throws -> [AppScreenshotSet]

    func listScreenshots(setId: String) async throws -> [AppScreenshot]

    func createLocalization(versionId: String, locale: String) async throws -> AppStoreVersionLocalization
    func createScreenshotSet(localizationId: String, displayType: ScreenshotDisplayType) async throws -> AppScreenshotSet
    func uploadScreenshot(setId: String, fileURL: URL) async throws -> AppScreenshot
}
