import Mockable
import Testing
@testable import Domain

@Suite
struct ScreenshotRepositoryTests {

    @Test
    func `list localizations returns localizations for version`() async throws {
        let mock = MockScreenshotRepository()
        let localizations = [
            MockRepositoryFactory.makeLocalization(id: "loc-1", locale: "en-US"),
            MockRepositoryFactory.makeLocalization(id: "loc-2", locale: "zh-Hans"),
        ]
        given(mock).listLocalizations(versionId: .any).willReturn(localizations)

        let result = try await mock.listLocalizations(versionId: "v1")
        #expect(result.count == 2)
        #expect(result[0].locale == "en-US")
        #expect(result[1].locale == "zh-Hans")
    }

    @Test
    func `list localizations returns empty when version has no localizations`() async throws {
        let mock = MockScreenshotRepository()
        given(mock).listLocalizations(versionId: .any).willReturn([])

        let result = try await mock.listLocalizations(versionId: "v1")
        #expect(result.isEmpty)
    }

    @Test
    func `list screenshot sets returns sets for localization`() async throws {
        let mock = MockScreenshotRepository()
        let sets = [
            MockRepositoryFactory.makeScreenshotSet(id: "set-1", displayType: .iphone67),
            MockRepositoryFactory.makeScreenshotSet(id: "set-2", displayType: .ipadPro3gen129),
        ]
        given(mock).listScreenshotSets(localizationId: .any).willReturn(sets)

        let result = try await mock.listScreenshotSets(localizationId: "loc-123")
        #expect(result.count == 2)
        #expect(result[0].screenshotDisplayType == .iphone67)
        #expect(result[1].screenshotDisplayType == .ipadPro3gen129)
    }

    @Test
    func `list screenshots returns screenshots for set`() async throws {
        let mock = MockScreenshotRepository()
        let screenshots = [
            MockRepositoryFactory.makeScreenshot(id: "img-1", fileName: "screen1.png"),
            MockRepositoryFactory.makeScreenshot(id: "img-2", fileName: "screen2.png"),
        ]
        given(mock).listScreenshots(setId: .any).willReturn(screenshots)

        let result = try await mock.listScreenshots(setId: "set-abc")
        #expect(result.count == 2)
        #expect(result[0].fileName == "screen1.png")
        #expect(result[1].fileName == "screen2.png")
    }

    @Test
    func `list screenshots returns empty for set with no screenshots`() async throws {
        let mock = MockScreenshotRepository()
        given(mock).listScreenshots(setId: .any).willReturn([])

        let result = try await mock.listScreenshots(setId: "empty-set")
        #expect(result.isEmpty)
    }
}
