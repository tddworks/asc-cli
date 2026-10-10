@preconcurrency import AppStoreConnect_Swift_SDK
import Foundation
import Testing
@testable import Domain
@testable import Infrastructure

@Suite
struct SDKSubscriptionReviewRepositoryUploadTests {

    @Test func `should reserve the review screenshot, commit it with its checksum and show it once processed`() async throws {
        let file = try UploadFixtures.file(named: "review.png", contents: "PNGDATA")
        let stub = StubAPIClient()
        stub.willReturnPages([
            try Self.screenshot(#"{"data":{"type":"subscriptionAppStoreReviewScreenshots","id":"rs-1","attributes":{"fileName":"review.png","fileSize":7,"uploadOperations":[]}},"links":{"self":""}}"#),
            try Self.screenshot(#"{"data":{"type":"subscriptionAppStoreReviewScreenshots","id":"rs-1","attributes":{"fileName":"review.png","fileSize":7}},"links":{"self":""}}"#),
            try Self.screenshot(#"{"data":{"type":"subscriptionAppStoreReviewScreenshots","id":"rs-1","attributes":{"fileName":"review.png","fileSize":7,"assetDeliveryState":{"state":"COMPLETE"},"imageAsset":{"templateUrl":"https://cdn/{w}x{h}bb.{f}","width":1242,"height":2688}}},"links":{"self":""}}"#),
        ])

        let screenshot = try await Self.repo(stub).uploadReviewScreenshot(subscriptionId: "sub-1", fileURL: file)

        #expect(screenshot == SubscriptionReviewScreenshot(id: "rs-1", subscriptionId: "sub-1", fileName: "review.png", fileSize: 7, assetState: .complete,
                                                           imageAsset: ImageAsset(templateUrl: "https://cdn/{w}x{h}bb.{f}", width: 1242, height: 2688)))
        #expect(stub.requests.map { "\($0.method) \($0.path) \($0.body ?? "")" } == [
            #"POST /v1/subscriptionAppStoreReviewScreenshots {"data":{"attributes":{"fileName":"review.png","fileSize":7},"relationships":{"subscription":{"data":{"id":"sub-1","type":"subscriptions"}}},"type":"subscriptionAppStoreReviewScreenshots"}}"#,
            #"PATCH /v1/subscriptionAppStoreReviewScreenshots/rs-1 {"data":{"attributes":{"sourceFileChecksum":"0b75926ab9a9f9fe7d6008245c09352e","uploaded":true},"id":"rs-1","type":"subscriptionAppStoreReviewScreenshots"}}"#,
            #"GET /v1/subscriptionAppStoreReviewScreenshots/rs-1 "#,
        ])
    }

    @Test func `should reserve the promotional image, commit it with its checksum and show it once processed`() async throws {
        let file = try UploadFixtures.file(named: "promo.png", contents: "PNGDATA")
        let stub = StubAPIClient()
        stub.willReturnPages([
            try Self.image(#"{"data":{"type":"subscriptionImages","id":"img-1","attributes":{"fileName":"promo.png","fileSize":7,"uploadOperations":[]}},"links":{"self":""}}"#),
            try Self.image(#"{"data":{"type":"subscriptionImages","id":"img-1","attributes":{"fileName":"promo.png","fileSize":7}},"links":{"self":""}}"#),
            try Self.image(#"{"data":{"type":"subscriptionImages","id":"img-1","attributes":{"fileName":"promo.png","fileSize":7,"state":"PREPARE_FOR_SUBMISSION","imageAsset":{"templateUrl":"https://cdn/{w}x{h}bb.{f}","width":1024,"height":1024}}},"links":{"self":""}}"#),
        ])

        let image = try await Self.repo(stub).uploadImage(subscriptionId: "sub-1", fileURL: file)

        #expect(image == SubscriptionPromotionalImage(id: "img-1", subscriptionId: "sub-1", fileName: "promo.png", fileSize: 7, state: .prepareForSubmission,
                                                      imageAsset: ImageAsset(templateUrl: "https://cdn/{w}x{h}bb.{f}", width: 1024, height: 1024)))
        #expect(stub.requests.map { "\($0.method) \($0.path) \($0.body ?? "")" } == [
            #"POST /v1/subscriptionImages {"data":{"attributes":{"fileName":"promo.png","fileSize":7},"relationships":{"subscription":{"data":{"id":"sub-1","type":"subscriptions"}}},"type":"subscriptionImages"}}"#,
            #"PATCH /v1/subscriptionImages/img-1 {"data":{"attributes":{"sourceFileChecksum":"0b75926ab9a9f9fe7d6008245c09352e","uploaded":true},"id":"img-1","type":"subscriptionImages"}}"#,
            #"GET /v1/subscriptionImages/img-1 "#,
        ])
    }

    @Test func `should fail without committing the review screenshot when App Store Connect's storage refuses a part`() async throws {
        let file = try UploadFixtures.file(named: "review.png", contents: "PNGDATA")
        let stub = StubAPIClient()
        stub.willReturn(try Self.screenshot(#"{"data":{"type":"subscriptionAppStoreReviewScreenshots","id":"rs-1","attributes":{"fileName":"review.png","fileSize":7,"uploadOperations":[{"method":"PUT","url":"https://upload.example.com/1","length":7,"offset":0}]}},"links":{"self":""}}"#))
        let http = SequencedStubHTTPClient()
        http.enqueue(json: "", statusCode: 500)

        await #expect(throws: (any Error).self) {
            try await Self.repo(stub, http: http).uploadReviewScreenshot(subscriptionId: "sub-1", fileURL: file)
        }
        #expect(stub.requests.map { "\($0.method) \($0.path)" } == ["POST /v1/subscriptionAppStoreReviewScreenshots"])
    }

    @Test func `should fail without committing the promotional image when App Store Connect's storage refuses a part`() async throws {
        let file = try UploadFixtures.file(named: "promo.png", contents: "PNGDATA")
        let stub = StubAPIClient()
        stub.willReturn(try Self.image(#"{"data":{"type":"subscriptionImages","id":"img-1","attributes":{"fileName":"promo.png","fileSize":7,"uploadOperations":[{"method":"PUT","url":"https://upload.example.com/1","length":7,"offset":0}]}},"links":{"self":""}}"#))
        let http = SequencedStubHTTPClient()
        http.enqueue(json: "", statusCode: 500)

        await #expect(throws: (any Error).self) {
            try await Self.repo(stub, http: http).uploadImage(subscriptionId: "sub-1", fileURL: file)
        }
        #expect(stub.requests.map { "\($0.method) \($0.path)" } == ["POST /v1/subscriptionImages"])
    }

    static func repo(_ stub: StubAPIClient, http: any HTTPPerforming = SequencedStubHTTPClient()) -> SDKSubscriptionReviewRepository {
        SDKSubscriptionReviewRepository(client: stub, uploader: UploadOperationsExecutor(http: http), pollDelayNanos: 0, pollMaxAttempts: 1)
    }

    static func screenshot(_ json: String) throws -> SubscriptionAppStoreReviewScreenshotResponse {
        try UploadFixtures.decode(SubscriptionAppStoreReviewScreenshotResponse.self, json)
    }

    static func image(_ json: String) throws -> SubscriptionImageResponse {
        try UploadFixtures.decode(SubscriptionImageResponse.self, json)
    }
}
