import Mockable

@Mockable
public protocol ScreenshotRepository: Sendable {
    func listScreenshotSets(localizationId: String) async throws -> [AppScreenshotSet]
    func listScreenshots(setId: String) async throws -> [AppScreenshot]
}
