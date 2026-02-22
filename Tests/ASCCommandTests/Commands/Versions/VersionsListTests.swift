import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct VersionsListTests {

    @Test func `execute json output`() async throws {
        let mockRepo = MockAppRepository()
        given(mockRepo).listVersions(appId: .any).willReturn([
            AppStoreVersion(id: "v-1", appId: "app-1", versionString: "2.3.0", platform: .iOS, state: .readyForSale),
        ])

        let cmd = try VersionsList.parse(["--app-id", "app-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listLocalizations" : "asc localizations list --version-id v-1",
                "listVersions" : "asc versions list --app-id app-1"
              },
              "appId" : "app-1",
              "id" : "v-1",
              "platform" : "IOS",
              "state" : "READY_FOR_SALE",
              "versionString" : "2.3.0"
            }
          ]
        }
        """)
    }
}
