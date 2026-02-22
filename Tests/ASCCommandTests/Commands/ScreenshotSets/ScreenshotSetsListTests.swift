import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct ScreenshotSetsListTests {

    @Test func `execute json output`() async throws {
        let mockRepo = MockScreenshotRepository()
        given(mockRepo).listScreenshotSets(localizationId: .any).willReturn([
            AppScreenshotSet(id: "set-1", localizationId: "loc-1", screenshotDisplayType: .iphone67, screenshotsCount: 3),
        ])

        let cmd = try ScreenshotSetsList.parse(["--localization-id", "loc-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listScreenshotSets" : "asc screenshot-sets list --localization-id loc-1",
                "listScreenshots" : "asc screenshots list --set-id set-1"
              },
              "id" : "set-1",
              "localizationId" : "loc-1",
              "screenshotDisplayType" : "APP_IPHONE_67",
              "screenshotsCount" : 3
            }
          ]
        }
        """)
    }

    @Test func `execute passes localizationId to repository`() async throws {
        let mockRepo = MockScreenshotRepository()
        given(mockRepo).listScreenshotSets(localizationId: .value("loc-99")).willReturn([])

        let cmd = try ScreenshotSetsList.parse(["--localization-id", "loc-99"])
        _ = try await cmd.execute(repo: mockRepo)
    }
}
