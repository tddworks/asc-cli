import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct AppInfoLocalizationsListTests {

    @Test func `listed app info localizations include affordances for navigation`() async throws {
        let mockRepo = MockAppInfoRepository()
        given(mockRepo).listLocalizations(appInfoId: .any).willReturn([
            AppInfoLocalization(id: "loc-1", appInfoId: "info-1", locale: "en-US", name: "My App", subtitle: "Do things"),
        ])

        let cmd = try AppInfoLocalizationsList.parse(["--app-info-id", "info-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listLocalizations" : "asc app-info-localizations list --app-info-id info-1",
                "updateLocalization" : "asc app-info-localizations update --localization-id loc-1"
              },
              "appInfoId" : "info-1",
              "id" : "loc-1",
              "locale" : "en-US",
              "name" : "My App",
              "subtitle" : "Do things"
            }
          ]
        }
        """)
    }
}
