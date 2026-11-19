import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct AppInfoLocalizationsUpdateTests {

    @Test func `updated app info localization is returned with affordances`() async throws {
        let mockRepo = MockAppInfos()
        given(mockRepo)
            .updateLocalization(id: .any, name: .any, subtitle: .any, privacyPolicyUrl: .any, privacyChoicesUrl: .any, privacyPolicyText: .any)
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
                "delete" : "asc app-info-localizations delete --localization-id loc-1",
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

    @Test func `update with privacy choices url and privacy policy text passes them through`() async throws {
        let mockRepo = MockAppInfos()
        var capturedChoicesUrl: String??
        var capturedPolicyText: String??
        given(mockRepo)
            .updateLocalization(id: .any, name: .any, subtitle: .any, privacyPolicyUrl: .any, privacyChoicesUrl: .any, privacyPolicyText: .any)
            .willProduce { _, _, _, _, choicesUrl, policyText in
                capturedChoicesUrl = choicesUrl
                capturedPolicyText = policyText
                return AppInfoLocalization(
                    id: "loc-2", appInfoId: "info-1", locale: "en-US",
                    privacyChoicesUrl: choicesUrl,
                    privacyPolicyText: policyText
                )
            }

        let cmd = try AppInfoLocalizationsUpdate.parse([
            "--localization-id", "loc-2",
            "--privacy-choices-url", "https://example.com/choices",
            "--privacy-policy-text", "Our privacy policy text",
            "--pretty",
        ])
        _ = try await cmd.execute(repo: mockRepo)

        #expect(capturedChoicesUrl == "https://example.com/choices")
        #expect(capturedPolicyText == "Our privacy policy text")
    }
}
