@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import ASCKit

@Suite
struct SDKBuildUploadRepositoryTests {

    @Test func `listBuildUploads injects appId into each upload`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(BuildUploadsResponse(
            data: [
                makeSdkBuildUpload(id: "up-1", state: .processing)
            ],
            links: .init(this: "")
        ))

        let repo = SDKBuildUploadRepository(client: stub)
        let uploads = try await repo.listBuildUploads(appId: "app-42")

        #expect(uploads.count == 1)
        #expect(uploads[0].appId == "app-42")
        #expect(uploads[0].state == .processing)
    }

    @Test func `listBuildUploads maps complete state`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(BuildUploadsResponse(
            data: [makeSdkBuildUpload(id: "up-1", state: .complete)],
            links: .init(this: "")
        ))

        let repo = SDKBuildUploadRepository(client: stub)
        let uploads = try await repo.listBuildUploads(appId: "app-1")

        #expect(uploads[0].state == .complete)
        #expect(uploads[0].state.isComplete)
    }

    @Test func `getBuildUpload maps state and injects empty appId`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(BuildUploadResponse(
            data: makeSdkBuildUpload(id: "up-99", state: .failed),
            links: .init(this: "")
        ))

        let repo = SDKBuildUploadRepository(client: stub)
        let upload = try await repo.getBuildUpload(id: "up-99")

        #expect(upload.id == "up-99")
        #expect(upload.state == .failed)
        #expect(upload.state.hasFailed)
        #expect(upload.appId == "")
    }

    @Test func `deleteBuildUpload calls void request`() async throws {
        let stub = StubAPIClient()
        let repo = SDKBuildUploadRepository(client: stub)

        try await repo.deleteBuildUpload(id: "up-1")

        #expect(stub.voidRequestCalled)
    }

    @Test func `failed upload maps error details`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(BuildUploadResponse(
            data: makeSdkBuildUpload(
                id: "up-1",
                state: .failed,
                errors: [.init(code: "INVALID_BINARY", description: "Binary is corrupt")],
                warnings: [.init(code: "MISSING_ICON", description: "Icon missing")]
            ),
            links: .init(this: "")
        ))

        let repo = SDKBuildUploadRepository(client: stub)
        let upload = try await repo.getBuildUpload(id: "up-1")

        #expect(upload.state == .failed)
        #expect(upload.errors.count == 1)
        #expect(upload.errors[0].code == "INVALID_BINARY")
        #expect(upload.errors[0].description == "Binary is corrupt")
        #expect(upload.warnings.count == 1)
        #expect(upload.warnings[0].code == "MISSING_ICON")
        #expect(upload.infos.isEmpty)
    }

    @Test func `successful upload has empty error arrays`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(BuildUploadResponse(
            data: makeSdkBuildUpload(id: "up-1", state: .complete),
            links: .init(this: "")
        ))

        let repo = SDKBuildUploadRepository(client: stub)
        let upload = try await repo.getBuildUpload(id: "up-1")

        #expect(upload.errors.isEmpty)
        #expect(upload.warnings.isEmpty)
        #expect(upload.infos.isEmpty)
    }

    // MARK: - Helpers

    private func makeSdkBuildUpload(
        id: String,
        state: AppStoreConnect_Swift_SDK.BuildUploadState,
        errors: [AppStoreConnect_Swift_SDK.StateDetail] = [],
        warnings: [AppStoreConnect_Swift_SDK.StateDetail] = [],
        infos: [AppStoreConnect_Swift_SDK.StateDetail] = []
    ) -> AppStoreConnect_Swift_SDK.BuildUpload {
        AppStoreConnect_Swift_SDK.BuildUpload(
            type: .buildUploads,
            id: id,
            attributes: .init(
                cfBundleShortVersionString: "1.0.0",
                cfBundleVersion: "42",
                state: .init(
                    errors: errors.isEmpty ? nil : errors,
                    warnings: warnings.isEmpty ? nil : warnings,
                    infos: infos.isEmpty ? nil : infos,
                    state: state
                ),
                platform: .ios
            )
        )
    }

    @Test func `build uploads list includes every upload beyond the first page`() async throws {
        func page(_ range: Range<Int>, nextCursor: String?) -> BuildUploadsResponse {
            BuildUploadsResponse(
                data: range.map { i in makeSdkBuildUpload(id: "item-\(i)", state: .complete) },
                links: .init(this: ""),
                meta: .init(paging: .init(total: 75, limit: 50, nextCursor: nextCursor))
            )
        }
        let stub = StubAPIClient()
        stub.willReturnPages([page(0..<50, nextCursor: "page-2"), page(50..<75, nextCursor: nil)])

        let repo = SDKBuildUploadRepository(client: stub)
        let result = try await repo.listBuildUploads(appId: "app-1")

        #expect(result.count == 75)
        #expect(result.last?.id == "item-74")
    }
}
