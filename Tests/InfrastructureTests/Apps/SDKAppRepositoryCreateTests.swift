@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKAppRepositoryCreateTests {

    @Test func `createVersion injects appId into response`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppStoreVersionResponse(
            data: AppStoreVersion(
                type: .appStoreVersions,
                id: "v-new",
                attributes: .init(platform: .ios, versionString: "2.0.0", appStoreState: .prepareForSubmission)
            ),
            links: .init(this: "")
        ))

        let repo = SDKAppRepository(client: stub)
        let result = try await repo.createVersion(appId: "app-42", versionString: "2.0.0", platform: .iOS)

        #expect(result.id == "v-new")
        #expect(result.appId == "app-42")
        #expect(result.versionString == "2.0.0")
        #expect(result.platform == .iOS)
        #expect(result.state == .prepareForSubmission)
    }

    @Test func `createVersion maps platform from SDK response`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppStoreVersionResponse(
            data: AppStoreVersion(
                type: .appStoreVersions,
                id: "v-1",
                attributes: .init(platform: .macOs, versionString: "1.0.0", appStoreState: .prepareForSubmission)
            ),
            links: .init(this: "")
        ))

        let repo = SDKAppRepository(client: stub)
        let result = try await repo.createVersion(appId: "app-1", versionString: "1.0.0", platform: .macOS)

        #expect(result.platform == .macOS)
    }
}
