import Foundation
import Testing
@testable import Domain

@Suite
struct InAppPurchaseReviewCodableTests {

    @Test func `review screenshot roundtrip preserves assetState`() throws {
        let s = InAppPurchaseReviewScreenshot(
            id: "rs-1", iapId: "iap-1", fileName: "review.png",
            fileSize: 1234, assetState: .complete
        )
        let data = try JSONEncoder().encode(s)
        let decoded = try JSONDecoder().decode(InAppPurchaseReviewScreenshot.self, from: data)
        #expect(decoded == s)
    }

    @Test func `review screenshot omits nil assetState from JSON`() throws {
        let s = InAppPurchaseReviewScreenshot(id: "rs-1", iapId: "iap-1", fileName: "review.png", fileSize: 1234)
        let json = String(decoding: try JSONEncoder().encode(s), as: UTF8.self)
        #expect(!json.contains("assetState"))
    }

    @Test func `promotional image roundtrip preserves state`() throws {
        let img = InAppPurchasePromotionalImage(
            id: "img-1", iapId: "iap-1", fileName: "promo.png",
            fileSize: 9999, state: .approved
        )
        let data = try JSONEncoder().encode(img)
        let decoded = try JSONDecoder().decode(InAppPurchasePromotionalImage.self, from: data)
        #expect(decoded == img)
    }

    @Test func `promotional image state raw values match ASC API`() {
        #expect(InAppPurchasePromotionalImage.ImageState.awaitingUpload.rawValue == "AWAITING_UPLOAD")
        #expect(InAppPurchasePromotionalImage.ImageState.uploadComplete.rawValue == "UPLOAD_COMPLETE")
        #expect(InAppPurchasePromotionalImage.ImageState.approved.rawValue == "APPROVED")
        #expect(InAppPurchasePromotionalImage.ImageState.rejected.rawValue == "REJECTED")
    }

    @Test func `assetState semantic booleans cover every case`() {
        let states: [(InAppPurchaseReviewScreenshot.AssetState, Bool, Bool)] = [
            (.awaitingUpload, false, false),
            (.uploadComplete, true, false),
            (.complete, true, false),
            (.failed, false, true),
        ]
        for (state, isComplete, hasFailed) in states {
            #expect(state.isComplete == isComplete)
            #expect(state.hasFailed == hasFailed)
        }
    }
}
