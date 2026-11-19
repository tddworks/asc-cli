import Mockable
import Testing
@testable import ASCKit

@Suite
struct AppStoreVersionsTests {

    @Test
    func `list versions returns versions for app`() async throws {
        let mock = MockAppStoreVersions()
        let versions = [
            MockRepositoryFactory.makeVersion(id: "v1", versionString: "2.1.0", platform: .iOS),
            MockRepositoryFactory.makeVersion(id: "v2", versionString: "1.5.0", platform: .macOS),
        ]
        given(mock).listVersions(appId: .any).willReturn(versions)

        let result = try await mock.listVersions(appId: "app-abc")
        #expect(result.count == 2)
        #expect(result[0].platform == .iOS)
        #expect(result[0].displayName == "iOS 2.1.0")
        #expect(result[1].platform == .macOS)
        #expect(result[1].displayName == "macOS 1.5.0")
    }

    @Test
    func `list versions returns empty when app has no versions`() async throws {
        let mock = MockAppStoreVersions()
        given(mock).listVersions(appId: .any).willReturn([])

        let result = try await mock.listVersions(appId: "new-app")
        #expect(result.isEmpty)
    }
}
