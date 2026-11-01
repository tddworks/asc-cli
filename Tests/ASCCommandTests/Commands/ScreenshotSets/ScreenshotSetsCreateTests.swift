import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct ScreenshotSetsCreateTests {

    @Test func `created screenshot set is returned with affordances`() async throws {
        let mockRepo = MockScreenshotRepository()
        given(mockRepo).createScreenshotSet(localizationId: .any, displayType: .any).willReturn(
            AppScreenshotSet(id: "set-new", localizationId: "loc-1", screenshotDisplayType: .iphone67, screenshotsCount: 0)
        )

        let cmd = try ScreenshotSetsCreate.parse(["--localization-id", "loc-1", "--display-type", "APP_IPHONE_67", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc screenshot-sets delete --set-id set-new",
                "listScreenshotSets" : "asc screenshot-sets list --localization-id loc-1",
                "listScreenshots" : "asc screenshots list --set-id set-new"
              },
              "id" : "set-new",
              "localizationId" : "loc-1",
              "screenshotDisplayType" : "APP_IPHONE_67",
              "screenshotsCount" : 0
            }
          ]
        }
        """)
    }

    @Test func `unknown display type throws validation error`() async throws {
        let mockRepo = MockScreenshotRepository()
        let cmd = try ScreenshotSetsCreate.parse(["--localization-id", "loc-1", "--display-type", "INVALID_TYPE"])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
    }

    @Test func `created iPad Pro 3gen11 set returns correct display type`() async throws {
        let mockRepo = MockScreenshotRepository()
        given(mockRepo).createScreenshotSet(localizationId: .any, displayType: .any).willReturn(
            AppScreenshotSet(id: "set-1", localizationId: "loc-42", screenshotDisplayType: .ipadPro3gen11)
        )

        let cmd = try ScreenshotSetsCreate.parse(["--localization-id", "loc-42", "--display-type", "APP_IPAD_PRO_3GEN_11", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc screenshot-sets delete --set-id set-1",
                "listScreenshotSets" : "asc screenshot-sets list --localization-id loc-42",
                "listScreenshots" : "asc screenshots list --set-id set-1"
              },
              "id" : "set-1",
              "localizationId" : "loc-42",
              "screenshotDisplayType" : "APP_IPAD_PRO_3GEN_11",
              "screenshotsCount" : 0
            }
          ]
        }
        """)
    }
}
