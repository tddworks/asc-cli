import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct BuildsUpdateBetaNotesTests {

    @Test func `execute returns localization with notes`() async throws {
        let mockRepo = MockBetaBuildLocalizations()
        given(mockRepo).upsertBetaBuildLocalization(buildId: .any, locale: .any, whatsNew: .any)
            .willReturn(BetaBuildLocalization(id: "bbl-1", buildId: "build-1", locale: "en-US", whatsNew: "Bug fixes"))

        let cmd = try BuildsUpdateBetaNotes.parse(["--build-id", "build-1", "--locale", "en-US", "--notes", "Bug fixes", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "updateNotes" : "asc builds update-beta-notes --build-id build-1 --locale en-US --notes <text>"
              },
              "buildId" : "build-1",
              "id" : "bbl-1",
              "locale" : "en-US",
              "whatsNew" : "Bug fixes"
            }
          ]
        }
        """)
    }

    @Test func `table output includes locale and notes fields`() async throws {
        let mockRepo = MockBetaBuildLocalizations()
        given(mockRepo).upsertBetaBuildLocalization(buildId: .any, locale: .any, whatsNew: .any)
            .willReturn(BetaBuildLocalization(id: "bbl-1", buildId: "build-1", locale: "en-US", whatsNew: "New feature"))

        let cmd = try BuildsUpdateBetaNotes.parse(["--build-id", "build-1", "--locale", "en-US", "--notes", "New feature", "--output", "table"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("bbl-1"))
        #expect(output.contains("en-US"))
        #expect(output.contains("New feature"))
    }
}
