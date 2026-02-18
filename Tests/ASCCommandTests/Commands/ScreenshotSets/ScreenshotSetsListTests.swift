import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct ScreenshotSetsListTests {

    @Test func `execute returns display type and count in output`() async throws {
        let mockRepo = MockScreenshotRepository()
        given(mockRepo).listScreenshotSets(localizationId: .any).willReturn([
            AppScreenshotSet(id: "set-1", localizationId: "loc-1", screenshotDisplayType: .iphone67, screenshotsCount: 3),
        ])

        let cmd = try ScreenshotSetsList.parse(["--localization-id", "loc-1"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("3"))
        #expect(output.contains("set-1"))
    }

    @Test func `execute json output contains affordances`() async throws {
        let mockRepo = MockScreenshotRepository()
        given(mockRepo).listScreenshotSets(localizationId: .any).willReturn([
            AppScreenshotSet(id: "set-1", localizationId: "loc-1", screenshotDisplayType: .iphone67, screenshotsCount: 0),
        ])

        let cmd = try ScreenshotSetsList.parse(["--localization-id", "loc-1"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("affordances"))
        #expect(output.contains("listScreenshots"))
    }

    @Test func `execute passes localizationId to repository`() async throws {
        let mockRepo = MockScreenshotRepository()
        given(mockRepo).listScreenshotSets(localizationId: .value("loc-99")).willReturn([])

        let cmd = try ScreenshotSetsList.parse(["--localization-id", "loc-99"])
        _ = try await cmd.execute(repo: mockRepo)
    }
}
