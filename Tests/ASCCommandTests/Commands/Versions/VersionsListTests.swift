import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct VersionsListTests {

    @Test func `execute json output contains version string and raw platform`() async throws {
        let mockRepo = MockAppRepository()
        given(mockRepo).listVersions(appId: .any).willReturn([
            AppStoreVersion(id: "v-1", appId: "app-1", versionString: "2.3.0", platform: .iOS, state: .readyForSale),
        ])

        let cmd = try VersionsList.parse(["--app-id", "app-1"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("2.3.0"))
        #expect(output.contains("IOS"))
        #expect(output.contains("READY_FOR_SALE"))
    }

    @Test func `execute json output contains affordances with listLocalizations`() async throws {
        let mockRepo = MockAppRepository()
        given(mockRepo).listVersions(appId: .any).willReturn([
            AppStoreVersion(id: "v-1", appId: "app-1", versionString: "1.0", platform: .iOS, state: .readyForSale),
        ])

        let cmd = try VersionsList.parse(["--app-id", "app-1"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("affordances"))
        #expect(output.contains("listLocalizations"))
    }
}
