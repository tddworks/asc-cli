import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct ReviewSubmissionItemsListTests {

    @Test func `listed items show id, submissionId, state, linked resource, and affordances`() async throws {
        let mockRepo = MockSubmissionRepository()
        given(mockRepo).listSubmissionItems(submissionId: .value("sub-1")).willReturn([
            ReviewSubmissionItem(
                id: "item-1",
                submissionId: "sub-1",
                state: .rejected,
                linkedResourceId: "v-9",
                linkedResourceType: .appStoreVersion
            ),
        ])

        let cmd = try ReviewSubmissionItemsList.parse(["--submission-id", "sub-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "getResolutionDetails" : "asc iris resolution-center get --submission-id sub-1",
                "getSubmission" : "asc review-submissions get --submission-id sub-1",
                "getVersion" : "asc versions get --version-id v-9",
                "listSiblings" : "asc review-submissions items list --submission-id sub-1"
              },
              "id" : "item-1",
              "linkedResourceId" : "v-9",
              "linkedResourceType" : "APP_STORE_VERSION",
              "state" : "REJECTED",
              "submissionId" : "sub-1"
            }
          ]
        }
        """)
    }

    @Test func `items filtered by state returns only matching items`() async throws {
        let mockRepo = MockSubmissionRepository()
        given(mockRepo).listSubmissionItems(submissionId: .value("sub-1")).willReturn([
            ReviewSubmissionItem(id: "i-1", submissionId: "sub-1", state: .rejected,
                                 linkedResourceId: "v-9", linkedResourceType: .appStoreVersion),
            ReviewSubmissionItem(id: "i-2", submissionId: "sub-1", state: .approved,
                                 linkedResourceId: "v-10", linkedResourceType: .appStoreVersion),
        ])

        let cmd = try ReviewSubmissionItemsList.parse([
            "--submission-id", "sub-1",
            "--state", "REJECTED",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("\"i-1\""))
        #expect(output.contains("\"REJECTED\""))
        #expect(!output.contains("\"i-2\""))
        #expect(!output.contains("\"APPROVED\""))
    }
}
