import Foundation
import Testing
@testable import Domain

@Suite
struct SubscriptionPromotionalImageTests {

    @Test func `image carries subscriptionId`() {
        let img = SubscriptionPromotionalImage(id: "img-1", subscriptionId: "sub-1",
                                               fileName: "promo.png", fileSize: 9999)
        #expect(img.subscriptionId == "sub-1")
        #expect(img.id == "img-1")
    }

    @Test func `affordances include listSiblings always`() {
        let img = SubscriptionPromotionalImage(id: "img-1", subscriptionId: "sub-1",
                                               fileName: "promo.png", fileSize: 9999, state: .approved)
        #expect(img.affordances["listSiblings"] == "asc subscription-images list --subscription-id sub-1")
    }

    @Test func `delete affordance offered when not pending review`() {
        let img = SubscriptionPromotionalImage(id: "img-1", subscriptionId: "sub-1",
                                               fileName: "promo.png", fileSize: 9999, state: .approved)
        #expect(img.affordances["delete"] == "asc subscription-images delete --image-id img-1")
    }

    @Test func `delete affordance suppressed while waiting for review`() {
        let img = SubscriptionPromotionalImage(id: "img-1", subscriptionId: "sub-1",
                                               fileName: "promo.png", fileSize: 9999, state: .waitingForReview)
        #expect(img.affordances["delete"] == nil)
        #expect(img.affordances["listSiblings"] == "asc subscription-images list --subscription-id sub-1")
    }

    @Test func `delete affordance offered when state is nil`() {
        let img = SubscriptionPromotionalImage(id: "img-1", subscriptionId: "sub-1",
                                               fileName: "promo.png", fileSize: 9999, state: nil)
        #expect(img.affordances["delete"] == "asc subscription-images delete --image-id img-1")
    }

    @Test func `image state isApproved when approved`() {
        #expect(SubscriptionPromotionalImage.ImageState.approved.isApproved == true)
        #expect(SubscriptionPromotionalImage.ImageState.approved.isPendingReview == false)
        #expect(SubscriptionPromotionalImage.ImageState.waitingForReview.isPendingReview == true)
        #expect(SubscriptionPromotionalImage.ImageState.waitingForReview.isApproved == false)
    }

    @Test func `image roundtrip preserves all fields`() throws {
        let img = SubscriptionPromotionalImage(id: "img-1", subscriptionId: "sub-1",
                                               fileName: "promo.png", fileSize: 9999, state: .approved)
        let data = try JSONEncoder().encode(img)
        let decoded = try JSONDecoder().decode(SubscriptionPromotionalImage.self, from: data)
        #expect(decoded == img)
    }

    @Test func `image omits state from JSON when nil`() throws {
        let img = SubscriptionPromotionalImage(id: "img-1", subscriptionId: "sub-1",
                                               fileName: "promo.png", fileSize: 9999, state: nil)
        let json = String(decoding: try JSONEncoder().encode(img), as: UTF8.self)
        #expect(!json.contains("\"state\""))
    }

    @Test func `image state raw values match ASC API`() {
        #expect(SubscriptionPromotionalImage.ImageState.awaitingUpload.rawValue == "AWAITING_UPLOAD")
        #expect(SubscriptionPromotionalImage.ImageState.uploadComplete.rawValue == "UPLOAD_COMPLETE")
        #expect(SubscriptionPromotionalImage.ImageState.approved.rawValue == "APPROVED")
        #expect(SubscriptionPromotionalImage.ImageState.rejected.rawValue == "REJECTED")
        #expect(SubscriptionPromotionalImage.ImageState.waitingForReview.rawValue == "WAITING_FOR_REVIEW")
    }

    @Test func `image exposes table headers and row`() {
        let img = SubscriptionPromotionalImage(id: "img-1", subscriptionId: "sub-1",
                                               fileName: "promo.png", fileSize: 9999, state: .approved)
        #expect(SubscriptionPromotionalImage.tableHeaders == ["ID", "File Name", "File Size", "State"])
        #expect(img.tableRow == ["img-1", "promo.png", "9999", "APPROVED"])
    }

    @Test func `apiLinks resolve REST paths via structured affordances`() {
        let img = SubscriptionPromotionalImage(id: "img-1", subscriptionId: "sub-1",
                                               fileName: "promo.png", fileSize: 9999, state: .approved)
        #expect(img.apiLinks["listSiblings"]?.href == "/api/v1/subscriptions/sub-1/images")
        #expect(img.apiLinks["listSiblings"]?.method == "GET")
        #expect(img.apiLinks["delete"]?.href == "/api/v1/subscription-images/img-1")
        #expect(img.apiLinks["delete"]?.method == "DELETE")
    }
}
