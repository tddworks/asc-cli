@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import ASCKit

@Suite
struct SDKProfileRepositoryTests {

    @Test func `listProfiles injects bundleIdId from request when filtering by bundle id`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(ProfilesWithoutIncludesResponse(
            data: [
                AppStoreConnect_Swift_SDK.Profile(
                    type: .profiles,
                    id: "prof-1",
                    attributes: .init(name: "My Profile", profileType: .iosAppStore, profileState: .active)
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKProfileRepository(client: stub)
        let result = try await repo.listProfiles(bundleIdId: "bid-99", profileType: nil)

        #expect(result[0].id == "prof-1")
        #expect(result[0].bundleIdId == "bid-99")
        #expect(result[0].profileType == .iosAppStore)
        #expect(result[0].isActive == true)
    }

    @Test func `listProfiles extracts bundleIdId from relationship when no filter`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(ProfilesResponse(
            data: [
                AppStoreConnect_Swift_SDK.Profile(
                    type: .profiles,
                    id: "prof-1",
                    attributes: .init(name: "My Profile", profileType: .macAppStore, profileState: .active),
                    relationships: .init(
                        bundleID: .init(data: .init(type: .bundleIDs, id: "bid-from-relationship"))
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKProfileRepository(client: stub)
        let result = try await repo.listProfiles(bundleIdId: nil, profileType: nil)

        #expect(result[0].bundleIdId == "bid-from-relationship")
        #expect(result[0].profileType == .macAppStore)
    }

    @Test func `deleteProfile calls void endpoint`() async throws {
        let stub = StubAPIClient()
        let repo = SDKProfileRepository(client: stub)

        try await repo.deleteProfile(id: "prof-1")

        #expect(stub.voidRequestCalled == true)
    }

    @Test func `profiles list for a bundle id includes every profile beyond the first page`() async throws {
        func page(_ range: Range<Int>, nextCursor: String?) -> ProfilesWithoutIncludesResponse {
            ProfilesWithoutIncludesResponse(
                data: range.map { i in AppStoreConnect_Swift_SDK.Profile(type: .profiles, id: "item-\(i)", attributes: .init(name: "P\(i)", profileType: .iosAppStore, profileState: .active)) },
                links: .init(this: ""),
                meta: .init(paging: .init(total: 75, limit: 50, nextCursor: nextCursor))
            )
        }
        let stub = StubAPIClient()
        stub.willReturnPages([page(0..<50, nextCursor: "page-2"), page(50..<75, nextCursor: nil)])

        let repo = SDKProfileRepository(client: stub)
        let result = try await repo.listProfiles(bundleIdId: "bid-1", profileType: nil)

        #expect(result.count == 75)
        #expect(result.last?.id == "item-74")
    }

    @Test func `profiles list includes every profile beyond the first page`() async throws {
        func page(_ range: Range<Int>, nextCursor: String?) -> ProfilesResponse {
            ProfilesResponse(
                data: range.map { i in AppStoreConnect_Swift_SDK.Profile(type: .profiles, id: "item-\(i)", attributes: .init(name: "P\(i)", profileType: .iosAppStore, profileState: .active)) },
                links: .init(this: ""),
                meta: .init(paging: .init(total: 75, limit: 50, nextCursor: nextCursor))
            )
        }
        let stub = StubAPIClient()
        stub.willReturnPages([page(0..<50, nextCursor: "page-2"), page(50..<75, nextCursor: nil)])

        let repo = SDKProfileRepository(client: stub)
        let result = try await repo.listProfiles(bundleIdId: nil, profileType: nil)

        #expect(result.count == 75)
        #expect(result.last?.id == "item-74")
    }

    @Test func `profiles list asks Apple for each profile's bundle id`() async throws {
        // Apple only links a profile to its bundle ID when asked via `include`.
        let stub = StubAPIClient()
        stub.willReturn(ProfilesResponse(data: [], links: .init(this: "")))

        let repo = SDKProfileRepository(client: stub)
        _ = try await repo.listProfiles(bundleIdId: nil, profileType: nil)

        let query = Dictionary(uniqueKeysWithValues: (stub.lastQuery ?? []).map { ($0.0, $0.1 ?? "") })
        #expect(query["include"] == "bundleId")
    }
}
