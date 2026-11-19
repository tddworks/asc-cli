@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import ASCKit

@Suite
struct SDKDevicesTests {

    @Test func `listDevices maps name udid and deviceClass`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(DevicesResponse(
            data: [
                AppStoreConnect_Swift_SDK.Device(
                    type: .devices,
                    id: "dev-1",
                    attributes: .init(
                        name: "My iPhone",
                        platform: .ios,
                        udid: "ABC-123",
                        deviceClass: .iphone,
                        status: .enabled,
                        model: "iPhone 16 Pro"
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKDevices(client: stub)
        let result = try await repo.listDevices(platform: nil)

        #expect(result[0].id == "dev-1")
        #expect(result[0].name == "My iPhone")
        #expect(result[0].udid == "ABC-123")
        #expect(result[0].deviceClass == .iPhone)
        #expect(result[0].platform == .iOS)
        #expect(result[0].model == "iPhone 16 Pro")
        #expect(result[0].isEnabled == true)
    }

    @Test func `listDevices maps disabled status`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(DevicesResponse(
            data: [
                AppStoreConnect_Swift_SDK.Device(
                    type: .devices,
                    id: "dev-1",
                    attributes: .init(name: "Old iPhone", platform: .ios, udid: "XYZ", deviceClass: .iphone, status: .disabled)
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKDevices(client: stub)
        let result = try await repo.listDevices(platform: nil)

        #expect(result[0].isEnabled == false)
    }

    @Test func `devices list includes every device beyond the first page`() async throws {
        func page(_ range: Range<Int>, nextCursor: String?) -> DevicesResponse {
            DevicesResponse(
                data: range.map { i in AppStoreConnect_Swift_SDK.Device(type: .devices, id: "item-\(i)", attributes: .init(name: "D\(i)", platform: .ios, udid: "U\(i)", deviceClass: .iphone, status: .enabled)) },
                links: .init(this: ""),
                meta: .init(paging: .init(total: 75, limit: 50, nextCursor: nextCursor))
            )
        }
        let stub = StubAPIClient()
        stub.willReturnPages([page(0..<50, nextCursor: "page-2"), page(50..<75, nextCursor: nil)])

        let repo = SDKDevices(client: stub)
        let result = try await repo.listDevices(platform: nil)

        #expect(result.count == 75)
        #expect(result.last?.id == "item-74")
    }
}
