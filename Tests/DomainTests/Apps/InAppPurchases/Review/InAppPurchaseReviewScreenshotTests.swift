import Testing
@testable import Domain

@Suite
struct InAppPurchaseReviewScreenshotTests {

    @Test func `review screenshot carries iapId`() {
        let s = InAppPurchaseReviewScreenshot(id: "rs-1", iapId: "iap-1", fileName: "review.png", fileSize: 1234)
        #expect(s.iapId == "iap-1")
    }

    @Test func `affordances include get and delete`() {
        let s = InAppPurchaseReviewScreenshot(id: "rs-1", iapId: "iap-1", fileName: "review.png", fileSize: 1234)
        #expect(s.affordances["get"] == "asc iap-review-screenshot get --iap-id iap-1")
        #expect(s.affordances["delete"] == "asc iap-review-screenshot delete --screenshot-id rs-1")
    }

    @Test func `image carries iapId`() {
        let img = InAppPurchasePromotionalImage(id: "img-1", iapId: "iap-1", fileName: "promo.png", fileSize: 9999)
        #expect(img.iapId == "iap-1")
    }

    @Test func `image affordances include listSiblings and delete`() {
        let img = InAppPurchasePromotionalImage(id: "img-1", iapId: "iap-1", fileName: "promo.png", fileSize: 9999)
        #expect(img.affordances["listSiblings"] == "asc iap-images list --iap-id iap-1")
        #expect(img.affordances["delete"] == "asc iap-images delete --image-id img-1")
    }

    @Test func `image state isApproved when approved`() {
        let s = InAppPurchasePromotionalImage.ImageState.approved
        #expect(s.isApproved == true)
        #expect(s.isPendingReview == false)
    }
}
