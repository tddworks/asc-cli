import Foundation
import Testing
@testable import Domain

@Suite
struct SubscriptionReviewCodableTests {

    @Test func `review screenshot roundtrip preserves assetState`() throws {
        let s = SubscriptionReviewScreenshot(
            id: "rs-1", subscriptionId: "sub-1", fileName: "review.png",
            fileSize: 1234, assetState: .uploadComplete
        )
        let data = try JSONEncoder().encode(s)
        let decoded = try JSONDecoder().decode(SubscriptionReviewScreenshot.self, from: data)
        #expect(decoded == s)
    }

    @Test func `assetState semantic booleans match expectations`() {
        #expect(SubscriptionReviewScreenshot.AssetState.uploadComplete.isComplete == true)
        #expect(SubscriptionReviewScreenshot.AssetState.complete.isComplete == true)
        #expect(SubscriptionReviewScreenshot.AssetState.awaitingUpload.isComplete == false)
        #expect(SubscriptionReviewScreenshot.AssetState.failed.hasFailed == true)
    }
}
