import Testing
@testable import Domain

@Suite
struct SubscriptionReviewScreenshotTests {

    @Test func `review screenshot carries subscriptionId`() {
        let s = SubscriptionReviewScreenshot(id: "rs-1", subscriptionId: "sub-1", fileName: "review.png", fileSize: 1234)
        #expect(s.subscriptionId == "sub-1")
    }

    @Test func `affordances include get, upload, and delete when upload is complete`() {
        let s = SubscriptionReviewScreenshot(id: "rs-1", subscriptionId: "sub-1", fileName: "review.png",
                                             fileSize: 1234, assetState: .complete)
        #expect(s.affordances["get"] == "asc subscription-review-screenshot get --subscription-id sub-1")
        #expect(s.affordances["delete"] == "asc subscription-review-screenshot delete --screenshot-id rs-1")
        #expect(s.affordances["upload"] == "asc subscription-review-screenshot upload --file <path> --subscription-id sub-1")
    }

    @Test func `delete affordance suppressed while awaiting upload`() {
        let s = SubscriptionReviewScreenshot(id: "rs-1", subscriptionId: "sub-1", fileName: "review.png",
                                             fileSize: 1234, assetState: .awaitingUpload)
        #expect(s.affordances["delete"] == nil)
        #expect(s.affordances["upload"] != nil)
    }
}
