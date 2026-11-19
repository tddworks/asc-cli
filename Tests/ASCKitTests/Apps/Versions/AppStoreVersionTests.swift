import Foundation
import Testing
@testable import ASCKit

@Suite
struct AppStoreVersionTests {

    @Test
    func `version carries parent appId`() {
        let version = MockRepositoryFactory.makeVersion(id: "v1", appId: "app-1")
        #expect(version.appId == "app-1")
    }

    @Test
    func `readyForSale version is live`() {
        let version = MockRepositoryFactory.makeVersion(state: .readyForSale)
        #expect(version.isLive == true)
        #expect(version.isEditable == false)
        #expect(version.isPending == false)
    }

    @Test
    func `prepareForSubmission version is editable`() {
        let version = MockRepositoryFactory.makeVersion(state: .prepareForSubmission)
        #expect(version.isLive == false)
        #expect(version.isEditable == true)
        #expect(version.isPending == false)
    }

    @Test
    func `inReview version is pending`() {
        let version = MockRepositoryFactory.makeVersion(state: .inReview)
        #expect(version.isPending == true)
        #expect(version.isEditable == false)
    }

    @Test
    func `displayName combines platform and version string`() {
        let version = MockRepositoryFactory.makeVersion(
            versionString: "2.1.0",
            platform: .iOS
        )
        #expect(version.displayName == "iOS 2.1.0")
    }

    @Test(arguments: zip(
        AppStorePlatform.allCases,
        ["iOS", "macOS", "tvOS", "watchOS", "visionOS"]
    ))
    func `platform displayName is human readable`(platform: AppStorePlatform, expected: String) {
        #expect(platform.displayName == expected)
    }

    @Test(arguments: zip(
        ["ios", "macos", "tvos", "watchos", "visionos"],
        AppStorePlatform.allCases
    ))
    func `platform cliArgument parses all platforms`(arg: String, expected: AppStorePlatform) {
        #expect(AppStorePlatform(cliArgument: arg) == expected)
    }

    @Test
    func `unknown platform cliArgument returns nil`() {
        #expect(AppStorePlatform(cliArgument: "unknown") == nil)
    }

    // MARK: - Codable round-trip

    @Test
    func `decode round-trip preserves all fields`() throws {
        let original = AppStoreVersion(
            id: "v-1", appId: "app-42", versionString: "2.0.0",
            platform: .macOS, state: .prepareForSubmission, buildId: "build-99"
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppStoreVersion.self, from: data)
        #expect(decoded.id == "v-1")
        #expect(decoded.appId == "app-42")
        #expect(decoded.versionString == "2.0.0")
        #expect(decoded.platform == .macOS)
        #expect(decoded.state == .prepareForSubmission)
        #expect(decoded.buildId == "build-99")
    }

    @Test
    func `decode round-trip omits buildId when nil`() throws {
        let original = AppStoreVersion(id: "v-2", appId: "app-1", versionString: "1.0.0", platform: .iOS, state: .readyForSale)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppStoreVersion.self, from: data)
        #expect(decoded.buildId == nil)
    }
}
