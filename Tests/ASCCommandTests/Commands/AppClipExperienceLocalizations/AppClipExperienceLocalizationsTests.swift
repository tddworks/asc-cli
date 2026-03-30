import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct AppClipExperienceLocalizationsListTests {

    @Test func `listed localizations include experienceId locale subtitle and affordances`() async throws {
        let mockRepo = MockAppClipRepository()
        given(mockRepo).listLocalizations(experienceId: .any).willReturn([
            AppClipDefaultExperienceLocalization(id: "loc-1", experienceId: "exp-1", locale: "en-US", subtitle: "Quick access")
        ])

        let cmd = try AppClipExperienceLocalizationsList.parse(["--experience-id", "exp-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc app-clip-experience-localizations delete --localization-id loc-1",
                "listLocalizations" : "asc app-clip-experience-localizations list --experience-id exp-1"
              },
              "experienceId" : "exp-1",
              "id" : "loc-1",
              "locale" : "en-US",
              "subtitle" : "Quick access"
            }
          ]
        }
        """)
    }

    @Test func `listed localizations omit nil subtitle from JSON`() async throws {
        let mockRepo = MockAppClipRepository()
        given(mockRepo).listLocalizations(experienceId: .any).willReturn([
            AppClipDefaultExperienceLocalization(id: "loc-1", experienceId: "exp-1", locale: "en-US", subtitle: nil)
        ])

        let cmd = try AppClipExperienceLocalizationsList.parse(["--experience-id", "exp-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc app-clip-experience-localizations delete --localization-id loc-1",
                "listLocalizations" : "asc app-clip-experience-localizations list --experience-id exp-1"
              },
              "experienceId" : "exp-1",
              "id" : "loc-1",
              "locale" : "en-US"
            }
          ]
        }
        """)
    }

    @Test func `table output includes localization id locale and subtitle`() async throws {
        let mockRepo = MockAppClipRepository()
        given(mockRepo).listLocalizations(experienceId: .any).willReturn([
            AppClipDefaultExperienceLocalization(id: "loc-1", experienceId: "exp-1", locale: "en-US", subtitle: "Quick access")
        ])

        let cmd = try AppClipExperienceLocalizationsList.parse(["--experience-id", "exp-1", "--output", "table"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("loc-1"))
        #expect(output.contains("en-US"))
        #expect(output.contains("Quick access"))
    }
}

@Suite
struct AppClipExperienceLocalizationsCreateTests {

    @Test func `create localization returns created localization with affordances`() async throws {
        let mockRepo = MockAppClipRepository()
        given(mockRepo).createLocalization(experienceId: .any, locale: .any, subtitle: .any).willReturn(
            AppClipDefaultExperienceLocalization(id: "loc-new", experienceId: "exp-1", locale: "fr-FR", subtitle: "Accès rapide")
        )

        let cmd = try AppClipExperienceLocalizationsCreate.parse([
            "--experience-id", "exp-1",
            "--locale", "fr-FR",
            "--subtitle", "Accès rapide",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc app-clip-experience-localizations delete --localization-id loc-new",
                "listLocalizations" : "asc app-clip-experience-localizations list --experience-id exp-1"
              },
              "experienceId" : "exp-1",
              "id" : "loc-new",
              "locale" : "fr-FR",
              "subtitle" : "Accès rapide"
            }
          ]
        }
        """)
    }
}

@Suite
struct AppClipExperienceLocalizationsDeleteTests {

    @Test func `accepts global options including pretty`() throws {
        let cmd = try AppClipExperienceLocalizationsDelete.parse(["--localization-id", "loc-1", "--pretty"])
        #expect(cmd.globals.pretty == true)
    }

    @Test func `delete localization calls repo with localization id`() async throws {
        let mockRepo = MockAppClipRepository()
        given(mockRepo).deleteLocalization(id: .any).willReturn(())

        let cmd = try AppClipExperienceLocalizationsDelete.parse(["--localization-id", "loc-1"])
        try await cmd.execute(repo: mockRepo)

        verify(mockRepo).deleteLocalization(id: .value("loc-1")).called(1)
    }
}
