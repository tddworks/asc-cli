import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct SubscriptionGroupLocalizationsListTests {

    @Test func `lists localizations and returns them with affordances`() async throws {
        let mockRepo = MockSubscriptionGroupLocalizationRepository()
        given(mockRepo).listLocalizations(groupId: .any).willReturn([
            SubscriptionGroupLocalization(id: "loc-1", groupId: "grp-1", locale: "en-US", name: "Premium")
        ])

        let cmd = try SubscriptionGroupLocalizationsList.parse(["--group-id", "grp-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc subscription-group-localizations delete --localization-id loc-1",
                "listSiblings" : "asc subscription-group-localizations list --group-id grp-1",
                "update" : "asc subscription-group-localizations update --localization-id loc-1 --name <name>"
              },
              "groupId" : "grp-1",
              "id" : "loc-1",
              "locale" : "en-US",
              "name" : "Premium"
            }
          ]
        }
        """)
    }
}

@Suite
struct SubscriptionGroupLocalizationsCreateTests {

    @Test func `create posts groupId, locale, name and customAppName`() async throws {
        let mockRepo = MockSubscriptionGroupLocalizationRepository()
        given(mockRepo).createLocalization(groupId: .any, locale: .any, name: .any, customAppName: .any)
            .willReturn(SubscriptionGroupLocalization(
                id: "loc-new", groupId: "grp-1", locale: "en-US",
                name: "Premium Plans", customAppName: "Premium App"
            ))

        let cmd = try SubscriptionGroupLocalizationsCreate.parse([
            "--group-id", "grp-1",
            "--locale", "en-US",
            "--name", "Premium Plans",
            "--custom-app-name", "Premium App",
        ])
        _ = try await cmd.execute(repo: mockRepo)

        verify(mockRepo).createLocalization(
            groupId: .value("grp-1"),
            locale: .value("en-US"),
            name: .value("Premium Plans"),
            customAppName: .value("Premium App")
        ).called(1)
    }
}

@Suite
struct SubscriptionGroupLocalizationsUpdateTests {

    @Test func `update passes localizationId, name and customAppName`() async throws {
        let mockRepo = MockSubscriptionGroupLocalizationRepository()
        given(mockRepo).updateLocalization(localizationId: .any, name: .any, customAppName: .any)
            .willReturn(SubscriptionGroupLocalization(id: "loc-1", groupId: "", locale: "en-US", name: "Renamed"))

        let cmd = try SubscriptionGroupLocalizationsUpdate.parse([
            "--localization-id", "loc-1",
            "--name", "Renamed",
        ])
        _ = try await cmd.execute(repo: mockRepo)

        verify(mockRepo).updateLocalization(
            localizationId: .value("loc-1"),
            name: .value("Renamed"),
            customAppName: .value(nil)
        ).called(1)
    }
}

@Suite
struct SubscriptionGroupLocalizationsDeleteTests {

    @Test func `delete calls repo with localization id`() async throws {
        let mockRepo = MockSubscriptionGroupLocalizationRepository()
        given(mockRepo).deleteLocalization(localizationId: .any).willReturn(())

        let cmd = try SubscriptionGroupLocalizationsDelete.parse(["--localization-id", "loc-1"])
        try await cmd.execute(repo: mockRepo)

        verify(mockRepo).deleteLocalization(localizationId: .value("loc-1")).called(1)
    }
}
