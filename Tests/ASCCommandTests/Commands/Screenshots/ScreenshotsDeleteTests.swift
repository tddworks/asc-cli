import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct ScreenshotsDeleteTests {

    @Test func `should delete the screenshot it was given`() async throws {
        let mockRepo = MockScreenshotRepository()
        given(mockRepo).deleteScreenshot(screenshotId: .value("shot-1")).willReturn()

        let cmd = try ScreenshotsDelete.parse(["--screenshot-id", "shot-1"])

        await #expect(throws: Never.self) {
            try await cmd.execute(repo: mockRepo)
        }
    }

    @Test func `should report the App Store Connect error when the screenshot cannot be deleted`() async throws {
        let mockRepo = MockScreenshotRepository()
        given(mockRepo).deleteScreenshot(screenshotId: .any).willThrow(APIError.notFound("shot-404"))

        let cmd = try ScreenshotsDelete.parse(["--screenshot-id", "shot-404"])

        await #expect(throws: APIError.notFound("shot-404")) {
            try await cmd.execute(repo: mockRepo)
        }
    }
}
