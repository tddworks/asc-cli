import Testing
@testable import ASCKit

@Suite
struct IrisStatusTests {

    @Test func `status from browser shows source`() {
        let status = IrisStatus(source: .browser, cookieCount: 5)
        #expect(status.source == .browser)
        #expect(status.cookieCount == 5)
    }

    @Test func `status from environment shows source`() {
        let status = IrisStatus(source: .environment, cookieCount: 3)
        #expect(status.source == .environment)
    }

    @Test func `affordances include iris apps list`() {
        let status = IrisStatus(source: .browser, cookieCount: 5)
        #expect(status.affordances["listApps"] == "asc iris apps list")
    }

    @Test func `affordances include iris apps create`() {
        let status = IrisStatus(source: .browser, cookieCount: 5)
        #expect(status.affordances["createApp"] == "asc iris apps create --name <name> --bundle-id <id> --sku <sku>")
    }
}
