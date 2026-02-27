@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct OpenAPIPreviewRepositoryTests {

    // MARK: - listPreviewSets

    @Test func `listPreviewSets injects localizationId into each set`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppPreviewSetsResponse(
            data: [
                AppPreviewSet(
                    type: .appPreviewSets,
                    id: "set-1",
                    attributes: .init(previewType: .iphone67)
                ),
                AppPreviewSet(
                    type: .appPreviewSets,
                    id: "set-2",
                    attributes: .init(previewType: .ipadPro3gen129)
                ),
            ],
            links: .init(this: "")
        ))

        let repo = OpenAPIPreviewRepository(client: stub)
        let result = try await repo.listPreviewSets(localizationId: "loc-99")

        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.localizationId == "loc-99" })
    }

    @Test func `listPreviewSets maps previewType from SDK attributes`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppPreviewSetsResponse(
            data: [
                AppPreviewSet(
                    type: .appPreviewSets,
                    id: "set-1",
                    attributes: .init(previewType: .iphone67)
                ),
            ],
            links: .init(this: "")
        ))

        let repo = OpenAPIPreviewRepository(client: stub)
        let result = try await repo.listPreviewSets(localizationId: "loc-1")

        #expect(result[0].previewType == .iphone67)
    }

    @Test func `listPreviewSets counts previews from relationships`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppPreviewSetsResponse(
            data: [
                AppPreviewSet(
                    type: .appPreviewSets,
                    id: "set-1",
                    attributes: .init(previewType: .iphone67),
                    relationships: .init(
                        appPreviews: .init(
                            data: [
                                .init(type: .appPreviews, id: "p-1"),
                                .init(type: .appPreviews, id: "p-2"),
                            ]
                        )
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = OpenAPIPreviewRepository(client: stub)
        let result = try await repo.listPreviewSets(localizationId: "loc-1")

        #expect(result[0].previewsCount == 2)
    }

    // MARK: - listPreviews

    @Test func `listPreviews injects setId into each preview`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppPreviewsResponse(
            data: [
                AppPreview(
                    type: .appPreviews,
                    id: "p-1",
                    attributes: .init(fileSize: 1024, fileName: "preview.mp4")
                ),
                AppPreview(
                    type: .appPreviews,
                    id: "p-2",
                    attributes: .init(fileSize: 2048, fileName: "preview2.mp4")
                ),
            ],
            links: .init(this: "")
        ))

        let repo = OpenAPIPreviewRepository(client: stub)
        let result = try await repo.listPreviews(setId: "set-42")

        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.setId == "set-42" })
    }

    @Test func `listPreviews maps videoDeliveryState from SDK response`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppPreviewsResponse(
            data: [
                AppPreview(
                    type: .appPreviews,
                    id: "p-1",
                    attributes: .init(
                        fileSize: 1024,
                        fileName: "preview.mp4",
                        videoDeliveryState: .init(state: .complete)
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = OpenAPIPreviewRepository(client: stub)
        let result = try await repo.listPreviews(setId: "set-1")

        #expect(result[0].videoDeliveryState == .complete)
    }

    @Test func `listPreviews maps processing videoDeliveryState`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppPreviewsResponse(
            data: [
                AppPreview(
                    type: .appPreviews,
                    id: "p-1",
                    attributes: .init(
                        fileSize: 1024,
                        fileName: "preview.mp4",
                        videoDeliveryState: .init(state: .processing)
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = OpenAPIPreviewRepository(client: stub)
        let result = try await repo.listPreviews(setId: "set-1")

        #expect(result[0].videoDeliveryState == .processing)
        #expect(result[0].isComplete == false)
    }

    // MARK: - createPreviewSet

    @Test func `createPreviewSet injects localizationId into response`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppPreviewSetResponse(
            data: AppPreviewSet(
                type: .appPreviewSets,
                id: "new-set",
                attributes: .init(previewType: .iphone67)
            ),
            links: .init(this: "")
        ))

        let repo = OpenAPIPreviewRepository(client: stub)
        let result = try await repo.createPreviewSet(localizationId: "loc-77", previewType: .iphone67)

        #expect(result.id == "new-set")
        #expect(result.localizationId == "loc-77")
        #expect(result.previewType == .iphone67)
    }
}
