import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct AppInfoLocalizationsUpdateTests {

    @Test func `updated app info localization is returned with affordances`() async throws {
        let mockRepo = MockAppInfoRepository()
        given(mockRepo)
            .updateLocalization(id: .any, name: .any, subtitle: .any, privacyPolicyUrl: .any)
            .willReturn(AppInfoLocalization(id: "loc-1", appInfoId: "info-1", locale: "en-US", name: "New Name", subtitle: "New Sub"))

        let cmd = try AppInfoLocalizationsUpdate.parse([
            "--localization-id", "loc-1",
            "--name", "New Name",
            "--subtitle", "New Sub",
            "--pretty",
        ])
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
              "name" : "New Name",
              "subtitle" : "New Sub"
            }
          ]
        }
        """)
    }
}
