@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import ASCKit

@Suite
struct SDKVersionRepositoryCreateTests {

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

        let repo = SDKAppStoreVersions(client: stub)
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

        let repo = SDKAppStoreVersions(client: stub)
        let result = try await repo.createVersion(appId: "app-1", versionString: "1.0.0", platform: .macOS)

        #expect(result.platform == .macOS)
    }

    @Test func `createVersion throws for unsupported platform`() async throws {
        let repo = SDKAppStoreVersions(client: StubAPIClient())
        await #expect(throws: (any Error).self) {
            try await repo.createVersion(appId: "app-1", versionString: "1.0.0", platform: .watchOS)
        }
    }

    @Test func `createVersion throws when mapped version has unknown platform`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppStoreVersionResponse(
            data: AppStoreVersion(
                type: .appStoreVersions,
                id: "v-bad",
                attributes: .init(platform: nil, versionString: "1.0.0", appStoreState: .prepareForSubmission)
            ),
            links: .init(this: "")
        ))

        let repo = SDKAppStoreVersions(client: stub)
        await #expect(throws: (any Error).self) {
            try await repo.createVersion(appId: "app-1", versionString: "1.0.0", platform: .iOS)
        }
    }
}
