@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Domain
@testable import Infrastructure

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

    // MARK: - Helpers

    private func makeSdkBuildUpload(
        id: String,
        state: AppStoreConnect_Swift_SDK.BuildUploadState
    ) -> AppStoreConnect_Swift_SDK.BuildUpload {
        AppStoreConnect_Swift_SDK.BuildUpload(
            type: .buildUploads,
            id: id,
            attributes: .init(
                cfBundleShortVersionString: "1.0.0",
                cfBundleVersion: "42",
                state: .init(state: state),
                platform: .ios
            )
        )
    }
}
