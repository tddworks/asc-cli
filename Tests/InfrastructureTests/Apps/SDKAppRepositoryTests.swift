@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKAppRepositoryTests {

    // MARK: - listVersions

    @Test func `listVersions injects appId into each version`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppStoreVersionsResponse(
            data: [
                AppStoreVersion(
                    type: .appStoreVersions,
                    id: "v-1",
                    attributes: .init(platform: .ios, versionString: "1.0.0", appStoreState: .readyForSale)
                ),
                AppStoreVersion(
                    type: .appStoreVersions,
                    id: "v-2",
                    attributes: .init(platform: .macOs, versionString: "1.0.0", appStoreState: .prepareForSubmission)
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKAppRepository(client: stub)
        let result = try await repo.listVersions(appId: "app-42")

        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.appId == "app-42" })
    }

    @Test func `listVersions maps versionString and platform`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppStoreVersionsResponse(
            data: [
                AppStoreVersion(
                    type: .appStoreVersions,
                    id: "v-1",
                    attributes: .init(platform: .ios, versionString: "2.3.0", appStoreState: .readyForSale)
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKAppRepository(client: stub)
        let result = try await repo.listVersions(appId: "app-1")

        #expect(result[0].versionString == "2.3.0")
        #expect(result[0].platform == .iOS)
    }

    // MARK: - getApp

    @Test func `getApp maps single app from SDK response`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppResponse(
            data: App(
                type: .apps,
                id: "app-99",
                attributes: .init(name: "Single App", bundleID: "com.single", sku: "S1")
            ),
            links: .init(this: "")
        ))

        let repo = SDKAppRepository(client: stub)
        let result = try await repo.getApp(id: "app-99")

        #expect(result.id == "app-99")
        #expect(result.displayName == "Single App")
        #expect(result.bundleId == "com.single")
    }

    // MARK: - listApps

    @Test func `listApps maps name bundleId and sku from SDK attributes`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppsResponse(
            data: [
                App(
                    type: .apps,
                    id: "app-1",
                    attributes: .init(name: "My App", bundleID: "com.example.app", sku: "APP001")
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKAppRepository(client: stub)
        let result = try await repo.listApps(limit: nil)

        #expect(result.data[0].id == "app-1")
        #expect(result.data[0].displayName == "My App")
        #expect(result.data[0].bundleId == "com.example.app")
        #expect(result.data[0].sku == "APP001")
    }
}
