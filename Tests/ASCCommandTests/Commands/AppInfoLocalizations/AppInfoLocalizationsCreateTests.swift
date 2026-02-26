import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct AppInfoLocalizationsCreateTests {

    @Test func `created localization is returned with id and locale`() async throws {
        let mockRepo = MockAppInfoRepository()
        given(mockRepo)
            .createLocalization(appInfoId: .any, locale: .any, name: .any)
            .willReturn(AppInfoLocalization(id: "loc-1", appInfoId: "info-1", locale: "en-US", name: "My App"))

        let cmd = try AppInfoLocalizationsCreate.parse([
            "--app-info-id", "info-1",
            "--locale", "en-US",
            "--name", "My App",
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
              "name" : "My App"
            }
          ]
        }
        """)
    }

    @Test func `table output includes all row fields`() async throws {
        let mockRepo = MockAppInfoRepository()
        given(mockRepo)
            .createLocalization(appInfoId: .any, locale: .any, name: .any)
            .willReturn(AppInfoLocalization(id: "loc-2", appInfoId: "info-1", locale: "zh-Hans", name: "我的应用", subtitle: "副标题"))

        let cmd = try AppInfoLocalizationsCreate.parse([
            "--app-info-id", "info-1",
            "--locale", "zh-Hans",
            "--name", "我的应用",
            "--output", "table",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("loc-2"))
        #expect(output.contains("zh-Hans"))
        #expect(output.contains("我的应用"))
        #expect(output.contains("副标题"))
    }
}
