import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct ScreenshotSetsDeleteTests {

    @Test func `should delete the screenshot set it was given`() async throws {
        let mockRepo = MockScreenshotRepository()
        given(mockRepo).deleteScreenshotSet(setId: .value("set-1")).willReturn()

        let cmd = try ScreenshotSetsDelete.parse(["--set-id", "set-1"])

        await #expect(throws: Never.self) {
            try await cmd.execute(repo: mockRepo)
        }
    }

    @Test func `should report the App Store Connect error when the set cannot be deleted`() async throws {
        let mockRepo = MockScreenshotRepository()
        given(mockRepo).deleteScreenshotSet(setId: .any).willThrow(APIError.notFound("set-404"))

        let cmd = try ScreenshotSetsDelete.parse(["--set-id", "set-404"])

        await #expect(throws: APIError.notFound("set-404")) {
            try await cmd.execute(repo: mockRepo)
        }
    }
}
