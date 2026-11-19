import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct BetaReviewDetailUpdateTests {

    @Test func `update detail shows updated contact info`() async throws {
        let mockRepo = MockBetaAppReviews()
        given(mockRepo).updateDetail(id: .value("d-1"), update: .any)
            .willReturn(
                BetaAppReviewDetail(
                    id: "d-1",
                    appId: "app-1",
                    contactFirstName: "Jane",
                    contactEmail: "jane@example.com",
                    notes: "Updated notes"
                )
            )

        let cmd = try BetaReviewDetailUpdate.parse([
            "--detail-id", "d-1",
            "--contact-first-name", "Jane",
            "--contact-email", "jane@example.com",
            "--notes", "Updated notes",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "getDetail" : "asc beta-review detail get --app-id app-1",
                "updateDetail" : "asc beta-review detail update --detail-id d-1"
              },
              "appId" : "app-1",
              "contactEmail" : "jane@example.com",
              "contactFirstName" : "Jane",
              "demoAccountRequired" : false,
              "id" : "d-1",
              "notes" : "Updated notes"
            }
          ]
        }
        """)
    }
}
