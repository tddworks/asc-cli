import Foundation
import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct IAPReviewScreenshotGetTests {

    @Test func `returns the screenshot when present`() async throws {
        let mockRepo = MockInAppPurchaseReviewRepository()
        given(mockRepo).getReviewScreenshot(iapId: .any).willReturn(
            InAppPurchaseReviewScreenshot(id: "rs-1", iapId: "iap-1", fileName: "review.png", fileSize: 1234)
        )

        let cmd = try IAPReviewScreenshotGet.parse(["--iap-id", "iap-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("\"id\" : \"rs-1\""))
        #expect(output.contains("\"iapId\" : \"iap-1\""))
    }

    @Test func `returns empty data array when no screenshot`() async throws {
        let mockRepo = MockInAppPurchaseReviewRepository()
        given(mockRepo).getReviewScreenshot(iapId: .any).willReturn(nil)

        let cmd = try IAPReviewScreenshotGet.parse(["--iap-id", "iap-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [

          ]
        }
        """)
    }
}

@Suite
struct IAPReviewScreenshotDeleteTests {

    @Test func `delete calls repo with screenshot id`() async throws {
        let mockRepo = MockInAppPurchaseReviewRepository()
        given(mockRepo).deleteReviewScreenshot(screenshotId: .any).willReturn(())

        let cmd = try IAPReviewScreenshotDelete.parse(["--screenshot-id", "rs-1"])
        try await cmd.execute(repo: mockRepo)

        verify(mockRepo).deleteReviewScreenshot(screenshotId: .value("rs-1")).called(1)
    }
}

@Suite
struct IAPImagesListTests {

    @Test func `lists promotional images with affordances`() async throws {
        let mockRepo = MockInAppPurchaseReviewRepository()
        given(mockRepo).listImages(iapId: .any).willReturn([
            InAppPurchasePromotionalImage(id: "img-1", iapId: "iap-1", fileName: "promo.png", fileSize: 9999)
        ])

        let cmd = try IAPImagesList.parse(["--iap-id", "iap-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("\"id\" : \"img-1\""))
        #expect(output.contains("\"iapId\" : \"iap-1\""))
        #expect(output.contains("\"listSiblings\" : \"asc iap-images list --iap-id iap-1\""))
    }
}

@Suite
struct IAPImagesDeleteTests {

    @Test func `delete image calls repo with image id`() async throws {
        let mockRepo = MockInAppPurchaseReviewRepository()
        given(mockRepo).deleteImage(imageId: .any).willReturn(())

        let cmd = try IAPImagesDelete.parse(["--image-id", "img-1"])
        try await cmd.execute(repo: mockRepo)

        verify(mockRepo).deleteImage(imageId: .value("img-1")).called(1)
    }
}
