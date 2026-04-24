import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct AppInfosListTests {

    @Test func `listed app infos include affordances for navigation`() async throws {
        let mockRepo = MockAppInfoRepository()
        given(mockRepo).listAppInfos(appId: .any).willReturn([
            AppInfo(id: "info-1", appId: "app-1"),
        ])

        let cmd = try AppInfosList.parse(["--app-id", "app-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "createLocalization" : "asc app-info-localizations create --app-info-id info-1",
                "getAgeRating" : "asc age-rating get --app-info-id info-1",
                "listAppInfos" : "asc app-infos list --app-id app-1",
                "listLocalizations" : "asc app-info-localizations list --app-info-id info-1",
                "updateCategories" : "asc app-infos update --app-info-id info-1"
              },
              "appId" : "app-1",
              "id" : "info-1"
            }
          ]
        }
        """)
    }
}
