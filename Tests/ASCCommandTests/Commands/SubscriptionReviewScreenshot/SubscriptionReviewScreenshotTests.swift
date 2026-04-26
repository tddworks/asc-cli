import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct SubscriptionReviewScreenshotGetTests {

    @Test func `returns the screenshot when present`() async throws {
        let mockRepo = MockSubscriptionReviewRepository()
        given(mockRepo).getReviewScreenshot(subscriptionId: .any).willReturn(
            SubscriptionReviewScreenshot(id: "rs-1", subscriptionId: "sub-1", fileName: "review.png", fileSize: 1234)
        )

        let cmd = try SubscriptionReviewScreenshotGet.parse(["--subscription-id", "sub-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("\"id\" : \"rs-1\""))
        #expect(output.contains("\"subscriptionId\" : \"sub-1\""))
    }
}

@Suite
struct SubscriptionReviewScreenshotDeleteTests {

    @Test func `delete calls repo with screenshot id`() async throws {
        let mockRepo = MockSubscriptionReviewRepository()
        given(mockRepo).deleteReviewScreenshot(screenshotId: .any).willReturn(())

        let cmd = try SubscriptionReviewScreenshotDelete.parse(["--screenshot-id", "rs-1"])
        try await cmd.execute(repo: mockRepo)

        verify(mockRepo).deleteReviewScreenshot(screenshotId: .value("rs-1")).called(1)
    }
}
