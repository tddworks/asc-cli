@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import ASCKit

@Suite
struct SDKVersionRepositoryTests {

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

        let repo = SDKVersionRepository(client: stub)
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

        let repo = SDKVersionRepository(client: stub)
        let result = try await repo.listVersions(appId: "app-1")

        #expect(result[0].versionString == "2.3.0")
        #expect(result[0].platform == .iOS)
    }

    // MARK: - getVersion

    @Test func `getVersion injects appId and buildId from relationships`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppStoreVersionResponse(
            data: AppStoreVersion(
                type: .appStoreVersions,
                id: "v-1",
                attributes: .init(platform: .ios, versionString: "1.0.0", appStoreState: .readyForSale),
                relationships: .init(
                    app: .init(data: .init(type: .apps, id: "app-42")),
                    build: .init(data: .init(type: .builds, id: "build-99"))
                )
            ),
            links: .init(this: "")
        ))

        let repo = SDKVersionRepository(client: stub)
        let result = try await repo.getVersion(id: "v-1")

        #expect(result.id == "v-1")
        #expect(result.appId == "app-42")
        #expect(result.buildId == "build-99")
        #expect(result.platform == .iOS)
    }

    @Test func `getVersion defaults appId to empty string when no app relationship`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppStoreVersionResponse(
            data: AppStoreVersion(
                type: .appStoreVersions,
                id: "v-2",
                attributes: .init(platform: .macOs, versionString: "2.0.0", appStoreState: .prepareForSubmission)
            ),
            links: .init(this: "")
        ))

        let repo = SDKVersionRepository(client: stub)
        let result = try await repo.getVersion(id: "v-2")

        #expect(result.appId == "")
        #expect(result.buildId == nil)
    }

    @Test func `getVersion throws when platform cannot be mapped`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppStoreVersionResponse(
            data: AppStoreVersion(
                type: .appStoreVersions,
                id: "v-bad",
                attributes: .init(platform: nil, versionString: "1.0.0", appStoreState: .readyForSale)
            ),
            links: .init(this: "")
        ))

        let repo = SDKVersionRepository(client: stub)
        await #expect(throws: (any Error).self) {
            try await repo.getVersion(id: "v-bad")
        }
    }

    // MARK: - setBuild

    @Test func `setBuild succeeds without error`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppStoreVersionResponse(
            data: AppStoreVersion(
                type: .appStoreVersions,
                id: "v-1",
                attributes: .init(platform: .ios, versionString: "1.0.0", appStoreState: .prepareForSubmission)
            ),
            links: .init(this: "")
        ))

        let repo = SDKVersionRepository(client: stub)
        try await repo.setBuild(versionId: "v-1", buildId: "build-42")
        // No error thrown = success
    }

    @Test func `versions list includes every version beyond the first page`() async throws {
        func page(_ range: Range<Int>, nextCursor: String?) -> AppStoreVersionsResponse {
            AppStoreVersionsResponse(
                data: range.map { i in AppStoreVersion(type: .appStoreVersions, id: "item-\(i)", attributes: .init(platform: .ios, versionString: "1.\(i)", appStoreState: .readyForSale)) },
                links: .init(this: ""),
                meta: .init(paging: .init(total: 75, limit: 50, nextCursor: nextCursor))
            )
        }
        let stub = StubAPIClient()
        stub.willReturnPages([page(0..<50, nextCursor: "page-2"), page(50..<75, nextCursor: nil)])

        let repo = SDKVersionRepository(client: stub)
        let result = try await repo.listVersions(appId: "app-1")

        #expect(result.count == 75)
        #expect(result.last?.id == "item-74")
    }
}
