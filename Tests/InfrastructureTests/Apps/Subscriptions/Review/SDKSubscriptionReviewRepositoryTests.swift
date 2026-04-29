@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKSubscriptionReviewRepositoryTests {

    @Test func `deleteReviewScreenshot performs void request`() async throws {
        let stub = StubAPIClient()
        let repo = SDKSubscriptionReviewRepository(client: stub)
        try await repo.deleteReviewScreenshot(screenshotId: "rs-1")
        #expect(stub.voidRequestCalled == true)
    }

    // MARK: - imageAsset processing-state guard

    @Test func `listImages drops imageAsset when SDK returns empty templateURL`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionImagesResponse(
            data: [
                AppStoreConnect_Swift_SDK.SubscriptionImage(
                    type: .subscriptionImages, id: "img-1",
                    attributes: .init(
                        fileSize: 1024, fileName: "promo.jpg",
                        imageAsset: AppStoreConnect_Swift_SDK.ImageAsset(templateURL: "", width: 0, height: 0),
                        state: .uploadComplete
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionReviewRepository(client: stub)
        let result = try await repo.listImages(subscriptionId: "sub-1")

        #expect(result[0].imageAsset == nil)
    }

    @Test func `listImages drops imageAsset when SDK returns zero dimensions`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionImagesResponse(
            data: [
                AppStoreConnect_Swift_SDK.SubscriptionImage(
                    type: .subscriptionImages, id: "img-1",
                    attributes: .init(
                        fileSize: 1024, fileName: "promo.jpg",
                        imageAsset: AppStoreConnect_Swift_SDK.ImageAsset(
                            templateURL: "https://cdn/{w}x{h}bb.{f}", width: 0, height: 0
                        ),
                        state: .uploadComplete
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionReviewRepository(client: stub)
        let result = try await repo.listImages(subscriptionId: "sub-1")

        #expect(result[0].imageAsset == nil)
    }

    @Test func `listImages preserves imageAsset when SDK returns fully processed values`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionImagesResponse(
            data: [
                AppStoreConnect_Swift_SDK.SubscriptionImage(
                    type: .subscriptionImages, id: "img-1",
                    attributes: .init(
                        fileSize: 1024, fileName: "promo.jpg",
                        imageAsset: AppStoreConnect_Swift_SDK.ImageAsset(
                            templateURL: "https://cdn/{w}x{h}bb.{f}", width: 1024, height: 1024
                        ),
                        state: .uploadComplete
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionReviewRepository(client: stub)
        let result = try await repo.listImages(subscriptionId: "sub-1")

        #expect(result[0].imageAsset?.templateUrl == "https://cdn/{w}x{h}bb.{f}")
        #expect(result[0].imageAsset?.width == 1024)
        #expect(result[0].imageAsset?.height == 1024)
    }
}
