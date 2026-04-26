import Testing
@testable import Domain

@Suite
struct InAppPurchaseReviewScreenshotTests {

    @Test func `review screenshot carries iapId`() {
        let s = InAppPurchaseReviewScreenshot(id: "rs-1", iapId: "iap-1", fileName: "review.png", fileSize: 1234)
        #expect(s.iapId == "iap-1")
    }

    @Test func `affordances include get, upload, and delete when upload is complete`() {
        let s = InAppPurchaseReviewScreenshot(id: "rs-1", iapId: "iap-1", fileName: "review.png",
                                              fileSize: 1234, assetState: .complete)
        #expect(s.affordances["get"] == "asc iap-review-screenshot get --iap-id iap-1")
        #expect(s.affordances["delete"] == "asc iap-review-screenshot delete --screenshot-id rs-1")
        #expect(s.affordances["upload"] == "asc iap-review-screenshot upload --iap-id iap-1 --file <path>")
    }

    @Test func `delete affordance is suppressed while awaiting upload`() {
        let s = InAppPurchaseReviewScreenshot(id: "rs-1", iapId: "iap-1", fileName: "review.png",
                                              fileSize: 1234, assetState: .awaitingUpload)
        #expect(s.affordances["delete"] == nil)
        // Re-uploading is always offered as recovery
        #expect(s.affordances["upload"] == "asc iap-review-screenshot upload --iap-id iap-1 --file <path>")
    }

    @Test func `delete is offered after a failed upload as recovery`() {
        let s = InAppPurchaseReviewScreenshot(id: "rs-1", iapId: "iap-1", fileName: "review.png",
                                              fileSize: 1234, assetState: .failed)
        #expect(s.affordances["delete"] == "asc iap-review-screenshot delete --screenshot-id rs-1")
    }

    @Test func `assetState isComplete is true for uploadComplete and complete`() {
        #expect(InAppPurchaseReviewScreenshot.AssetState.uploadComplete.isComplete == true)
        #expect(InAppPurchaseReviewScreenshot.AssetState.complete.isComplete == true)
        #expect(InAppPurchaseReviewScreenshot.AssetState.awaitingUpload.isComplete == false)
        #expect(InAppPurchaseReviewScreenshot.AssetState.failed.hasFailed == true)
    }

    @Test func `image carries iapId`() {
        let img = InAppPurchasePromotionalImage(id: "img-1", iapId: "iap-1", fileName: "promo.png", fileSize: 9999)
        #expect(img.iapId == "iap-1")
    }

    @Test func `image affordances include listSiblings and delete when not in review`() {
        let img = InAppPurchasePromotionalImage(id: "img-1", iapId: "iap-1", fileName: "promo.png",
                                                fileSize: 9999, state: .approved)
        #expect(img.affordances["listSiblings"] == "asc iap-images list --iap-id iap-1")
        #expect(img.affordances["delete"] == "asc iap-images delete --image-id img-1")
    }

    @Test func `image delete affordance suppressed while pending review`() {
        let img = InAppPurchasePromotionalImage(id: "img-1", iapId: "iap-1", fileName: "promo.png",
                                                fileSize: 9999, state: .waitingForReview)
        #expect(img.affordances["delete"] == nil)
        #expect(img.affordances["listSiblings"] == "asc iap-images list --iap-id iap-1")
    }

    @Test func `image state isApproved when approved`() {
        let s = InAppPurchasePromotionalImage.ImageState.approved
        #expect(s.isApproved == true)
        #expect(s.isPendingReview == false)
    }
}
