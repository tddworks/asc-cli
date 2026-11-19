import Testing
@testable import ASCKit

@Suite
struct BundleIDTests {

    @Test func `bundle id carries all fields`() {
        let bundleId = MockRepositoryFactory.makeBundleID(
            id: "bid-1",
            name: "My App",
            identifier: "com.example.app",
            platform: .iOS,
            seedID: "SEED123"
        )
        #expect(bundleId.id == "bid-1")
        #expect(bundleId.name == "My App")
        #expect(bundleId.identifier == "com.example.app")
        #expect(bundleId.platform == .iOS)
        #expect(bundleId.seedID == "SEED123")
    }

    @Test func `bundle id seed id is nil when not provided`() {
        let bundleId = MockRepositoryFactory.makeBundleID()
        #expect(bundleId.seedID == nil)
    }

    @Test func `bundle id platform raw values match asc api`() {
        #expect(BundleIDPlatform.iOS.rawValue == "IOS")
        #expect(BundleIDPlatform.macOS.rawValue == "MAC_OS")
        #expect(BundleIDPlatform.universal.rawValue == "UNIVERSAL")
        #expect(BundleIDPlatform.services.rawValue == "SERVICES")
    }

    @Test func `bundle id platform accepts cli argument strings`() {
        #expect(BundleIDPlatform(cliArgument: "ios") == .iOS)
        #expect(BundleIDPlatform(cliArgument: "macos") == .macOS)
        #expect(BundleIDPlatform(cliArgument: "universal") == .universal)
        #expect(BundleIDPlatform(cliArgument: "services") == .services)
        #expect(BundleIDPlatform(cliArgument: "invalid") == nil)
    }

    @Test func `bundle id platform displayName is human readable`() {
        #expect(BundleIDPlatform.iOS.displayName == "iOS")
        #expect(BundleIDPlatform.macOS.displayName == "macOS")
        #expect(BundleIDPlatform.universal.displayName == "Universal")
        #expect(BundleIDPlatform.services.displayName == "Services")
    }
}
