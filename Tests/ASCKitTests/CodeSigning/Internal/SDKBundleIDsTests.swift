@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import ASCKit

@Suite
struct SDKBundleIDsTests {

    @Test func `listBundleIDs maps identifier and platform`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(BundleIDsResponse(
            data: [
                AppStoreConnect_Swift_SDK.BundleID(
                    type: .bundleIDs,
                    id: "bid-1",
                    attributes: .init(name: "My App", platform: .ios, identifier: "com.example.app")
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKBundleIDs(client: stub)
        let result = try await repo.listBundleIDs(platform: nil, identifier: nil)

        #expect(result[0].id == "bid-1")
        #expect(result[0].name == "My App")
        #expect(result[0].identifier == "com.example.app")
        #expect(result[0].platform == .iOS)
    }

    @Test func `listBundleIDs maps macOS platform`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(BundleIDsResponse(
            data: [
                AppStoreConnect_Swift_SDK.BundleID(
                    type: .bundleIDs,
                    id: "bid-2",
                    attributes: .init(name: "Mac App", platform: .macOs, identifier: "com.example.mac")
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKBundleIDs(client: stub)
        let result = try await repo.listBundleIDs(platform: nil, identifier: nil)

        #expect(result[0].platform == .macOS)
    }

    @Test func `deleteBundleID calls void endpoint`() async throws {
        let stub = StubAPIClient()
        let repo = SDKBundleIDs(client: stub)

        try await repo.deleteBundleID(id: "bid-1")

        #expect(stub.voidRequestCalled == true)
    }

    @Test func `bundle ids list includes every bundle id beyond the first page`() async throws {
        func page(_ range: Range<Int>, nextCursor: String?) -> BundleIDsResponse {
            BundleIDsResponse(
                data: range.map { i in AppStoreConnect_Swift_SDK.BundleID(type: .bundleIDs, id: "item-\(i)", attributes: .init(name: "B\(i)", platform: .ios, identifier: "com.example.b\(i)")) },
                links: .init(this: ""),
                meta: .init(paging: .init(total: 75, limit: 50, nextCursor: nextCursor))
            )
        }
        let stub = StubAPIClient()
        stub.willReturnPages([page(0..<50, nextCursor: "page-2"), page(50..<75, nextCursor: nil)])

        let repo = SDKBundleIDs(client: stub)
        let result = try await repo.listBundleIDs(platform: nil, identifier: nil)

        #expect(result.count == 75)
        #expect(result.last?.id == "item-74")
    }
}
