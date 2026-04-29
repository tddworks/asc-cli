@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKInAppPurchaseReviewRepositoryTests {

    // MARK: - listImages

    @Test func `listImages injects iapId into each image`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchaseImagesResponse(
            data: [
                AppStoreConnect_Swift_SDK.InAppPurchaseImage(
                    type: .inAppPurchaseImages, id: "img-1",
                    attributes: .init(fileSize: 1024, fileName: "promo1.png")
                ),
                AppStoreConnect_Swift_SDK.InAppPurchaseImage(
                    type: .inAppPurchaseImages, id: "img-2",
                    attributes: .init(fileSize: 2048, fileName: "promo2.png")
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseReviewRepository(client: stub)
        let result = try await repo.listImages(iapId: "iap-77")

        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.iapId == "iap-77" })
    }

    @Test func `listImages maps fileName, fileSize and state`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchaseImagesResponse(
            data: [
                AppStoreConnect_Swift_SDK.InAppPurchaseImage(
                    type: .inAppPurchaseImages, id: "img-1",
                    attributes: .init(fileSize: 1024, fileName: "promo.png", state: .approved)
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseReviewRepository(client: stub)
        let result = try await repo.listImages(iapId: "iap-1")

        #expect(result[0].fileName == "promo.png")
        #expect(result[0].fileSize == 1024)
        #expect(result[0].state == .approved)
    }

    // MARK: - imageAsset processing-state guard

    @Test func `listImages drops imageAsset when SDK returns empty templateURL`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchaseImagesResponse(
            data: [
                AppStoreConnect_Swift_SDK.InAppPurchaseImage(
                    type: .inAppPurchaseImages, id: "img-1",
                    attributes: .init(
                        fileSize: 1024, fileName: "promo.jpg",
                        imageAsset: AppStoreConnect_Swift_SDK.ImageAsset(templateURL: "", width: 0, height: 0),
                        state: .uploadComplete
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseReviewRepository(client: stub)
        let result = try await repo.listImages(iapId: "iap-1")

        #expect(result[0].imageAsset == nil)
    }

    @Test func `listImages drops imageAsset when SDK returns zero dimensions`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchaseImagesResponse(
            data: [
                AppStoreConnect_Swift_SDK.InAppPurchaseImage(
                    type: .inAppPurchaseImages, id: "img-1",
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

        let repo = SDKInAppPurchaseReviewRepository(client: stub)
        let result = try await repo.listImages(iapId: "iap-1")

        #expect(result[0].imageAsset == nil)
    }

    @Test func `listImages preserves imageAsset when SDK returns fully processed values`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchaseImagesResponse(
            data: [
                AppStoreConnect_Swift_SDK.InAppPurchaseImage(
                    type: .inAppPurchaseImages, id: "img-1",
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

        let repo = SDKInAppPurchaseReviewRepository(client: stub)
        let result = try await repo.listImages(iapId: "iap-1")

        #expect(result[0].imageAsset?.templateUrl == "https://cdn/{w}x{h}bb.{f}")
        #expect(result[0].imageAsset?.width == 1024)
        #expect(result[0].imageAsset?.height == 1024)
    }

    // MARK: - delete

    @Test func `deleteReviewScreenshot performs void request`() async throws {
        let stub = StubAPIClient()
        let repo = SDKInAppPurchaseReviewRepository(client: stub)
        try await repo.deleteReviewScreenshot(screenshotId: "rs-1")
        #expect(stub.voidRequestCalled == true)
    }

    @Test func `deleteImage performs void request`() async throws {
        let stub = StubAPIClient()
        let repo = SDKInAppPurchaseReviewRepository(client: stub)
        try await repo.deleteImage(imageId: "img-1")
        #expect(stub.voidRequestCalled == true)
    }
}
