import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct AppClipExperiencesListTests {

    @Test func `listed experiences include appClipId action and affordances`() async throws {
        let mockRepo = MockAppClipRepository()
        given(mockRepo).listExperiences(appClipId: .any).willReturn([
            AppClipDefaultExperience(id: "exp-1", appClipId: "clip-1", action: .open)
        ])

        let cmd = try AppClipExperiencesList.parse(["--app-clip-id", "clip-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "action" : "OPEN",
              "affordances" : {
                "delete" : "asc app-clip-experiences delete --experience-id exp-1",
                "listExperiences" : "asc app-clip-experiences list --app-clip-id clip-1",
                "listLocalizations" : "asc app-clip-experience-localizations list --experience-id exp-1"
              },
              "appClipId" : "clip-1",
              "id" : "exp-1"
            }
          ]
        }
        """)
    }

    @Test func `listed experiences omit nil action from JSON`() async throws {
        let mockRepo = MockAppClipRepository()
        given(mockRepo).listExperiences(appClipId: .any).willReturn([
            AppClipDefaultExperience(id: "exp-1", appClipId: "clip-1", action: nil)
        ])

        let cmd = try AppClipExperiencesList.parse(["--app-clip-id", "clip-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc app-clip-experiences delete --experience-id exp-1",
                "listExperiences" : "asc app-clip-experiences list --app-clip-id clip-1",
                "listLocalizations" : "asc app-clip-experience-localizations list --experience-id exp-1"
              },
              "appClipId" : "clip-1",
              "id" : "exp-1"
            }
          ]
        }
        """)
    }

    @Test func `table output includes experience id and action`() async throws {
        let mockRepo = MockAppClipRepository()
        given(mockRepo).listExperiences(appClipId: .any).willReturn([
            AppClipDefaultExperience(id: "exp-1", appClipId: "clip-1", action: .open)
        ])

        let cmd = try AppClipExperiencesList.parse(["--app-clip-id", "clip-1", "--output", "table"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("exp-1"))
        #expect(output.contains("clip-1"))
        #expect(output.contains("OPEN"))
    }
}

@Suite
struct AppClipExperiencesCreateTests {

    @Test func `create experience returns created experience with affordances`() async throws {
        let mockRepo = MockAppClipRepository()
        given(mockRepo).createExperience(appClipId: .any, action: .any).willReturn(
            AppClipDefaultExperience(id: "exp-new", appClipId: "clip-1", action: .view)
        )

        let cmd = try AppClipExperiencesCreate.parse(["--app-clip-id", "clip-1", "--action", "VIEW", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "action" : "VIEW",
              "affordances" : {
                "delete" : "asc app-clip-experiences delete --experience-id exp-new",
                "listExperiences" : "asc app-clip-experiences list --app-clip-id clip-1",
                "listLocalizations" : "asc app-clip-experience-localizations list --experience-id exp-new"
              },
              "appClipId" : "clip-1",
              "id" : "exp-new"
            }
          ]
        }
        """)
    }

    @Test func `create experience without action creates with nil action`() async throws {
        let mockRepo = MockAppClipRepository()
        given(mockRepo).createExperience(appClipId: .any, action: .any).willReturn(
            AppClipDefaultExperience(id: "exp-new", appClipId: "clip-1", action: nil)
        )

        let cmd = try AppClipExperiencesCreate.parse(["--app-clip-id", "clip-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc app-clip-experiences delete --experience-id exp-new",
                "listExperiences" : "asc app-clip-experiences list --app-clip-id clip-1",
                "listLocalizations" : "asc app-clip-experience-localizations list --experience-id exp-new"
              },
              "appClipId" : "clip-1",
              "id" : "exp-new"
            }
          ]
        }
        """)
    }
}

@Suite
struct AppClipExperiencesDeleteTests {

    @Test func `accepts global options including pretty`() throws {
        let cmd = try AppClipExperiencesDelete.parse(["--experience-id", "exp-1", "--pretty"])
        #expect(cmd.globals.pretty == true)
    }

    @Test func `delete experience calls repo with experience id`() async throws {
        let mockRepo = MockAppClipRepository()
        given(mockRepo).deleteExperience(id: .any).willReturn(())

        let cmd = try AppClipExperiencesDelete.parse(["--experience-id", "exp-1"])
        try await cmd.execute(repo: mockRepo)

        verify(mockRepo).deleteExperience(id: .value("exp-1")).called(1)
    }
}
