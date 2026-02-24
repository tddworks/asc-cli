import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct LocalizationsUpdateTests {

    @Test func `updated localization is returned with whatsNew text`() async throws {
        let mockRepo = MockVersionLocalizationRepository()
        given(mockRepo).updateLocalization(
            localizationId: .any,
            whatsNew: .any,
            description: .any,
            keywords: .any,
            marketingUrl: .any,
            supportUrl: .any,
            promotionalText: .any
        ).willReturn(
            AppStoreVersionLocalization(
                id: "loc-1",
                versionId: "v-1",
                locale: "en-US",
                whatsNew: "Bug fixes and performance improvements"
            )
        )

        let cmd = try LocalizationsUpdate.parse([
            "--localization-id", "loc-1",
            "--whats-new", "Bug fixes and performance improvements",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listLocalizations" : "asc localizations list --version-id v-1",
                "listScreenshotSets" : "asc screenshot-sets list --localization-id loc-1",
                "updateLocalization" : "asc localizations update --localization-id loc-1"
              },
              "id" : "loc-1",
              "locale" : "en-US",
              "versionId" : "v-1",
              "whatsNew" : "Bug fixes and performance improvements"
            }
          ]
        }
        """)
    }

    @Test func `update with all optional fields returns full content`() async throws {
        let mockRepo = MockVersionLocalizationRepository()
        given(mockRepo).updateLocalization(
            localizationId: .any,
            whatsNew: .any,
            description: .any,
            keywords: .any,
            marketingUrl: .any,
            supportUrl: .any,
            promotionalText: .any
        ).willReturn(
            AppStoreVersionLocalization(
                id: "loc-1",
                versionId: "v-1",
                locale: "zh-Hans",
                whatsNew: "新功能",
                description: "应用描述",
                keywords: "关键词",
                marketingUrl: "https://example.com",
                supportUrl: "https://support.example.com",
                promotionalText: "促销文本"
            )
        )

        let cmd = try LocalizationsUpdate.parse([
            "--localization-id", "loc-1",
            "--whats-new", "新功能",
            "--description", "应用描述",
            "--keywords", "关键词",
            "--marketing-url", "https://example.com",
            "--support-url", "https://support.example.com",
            "--promotional-text", "促销文本",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listLocalizations" : "asc localizations list --version-id v-1",
                "listScreenshotSets" : "asc screenshot-sets list --localization-id loc-1",
                "updateLocalization" : "asc localizations update --localization-id loc-1"
              },
              "description" : "应用描述",
              "id" : "loc-1",
              "keywords" : "关键词",
              "locale" : "zh-Hans",
              "marketingUrl" : "https:\\/\\/example.com",
              "promotionalText" : "促销文本",
              "supportUrl" : "https:\\/\\/support.example.com",
              "versionId" : "v-1",
              "whatsNew" : "新功能"
            }
          ]
        }
        """)
    }
}
