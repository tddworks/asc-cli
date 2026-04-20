import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct ReviewSubmissionsListTests {

    @Test func `listed submissions show id, appId, state, platform, and affordances`() async throws {
        let mockRepo = MockSubmissionRepository()
        given(mockRepo).listSubmissions(appId: .value("app-42"), states: .any, limit: .any)
            .willReturn([
                ReviewSubmission(id: "sub-1", appId: "app-42", platform: .iOS, state: .waitingForReview),
            ])

        let cmd = try ReviewSubmissionsList.parse(["--app-id", "app-42", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listVersions" : "asc versions list --app-id app-42"
              },
              "appId" : "app-42",
              "id" : "sub-1",
              "platform" : "IOS",
              "state" : "WAITING_FOR_REVIEW"
            }
          ]
        }
        """)
    }

    @Test func `state filter parses comma-separated values and passes them to repo`() async throws {
        let mockRepo = MockSubmissionRepository()
        given(mockRepo).listSubmissions(
            appId: .value("app-1"),
            states: .value([.waitingForReview, .inReview, .readyForReview]),
            limit: .value(200)
        ).willReturn([])

        let cmd = try ReviewSubmissionsList.parse([
            "--app-id", "app-1",
            "--state", "WAITING_FOR_REVIEW,IN_REVIEW,READY_FOR_REVIEW",
            "--limit", "200",
            "--pretty"
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [

          ]
        }
        """)
    }

    @Test func `unresolved issues state is preserved through listing`() async throws {
        let mockRepo = MockSubmissionRepository()
        given(mockRepo).listSubmissions(
            appId: .value("app-1"),
            states: .value([.unresolvedIssues]),
            limit: .any
        ).willReturn([
            ReviewSubmission(id: "sub-u", appId: "app-1", platform: .iOS, state: .unresolvedIssues),
        ])

        let cmd = try ReviewSubmissionsList.parse([
            "--app-id", "app-1",
            "--state", "UNRESOLVED_ISSUES"
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("\"UNRESOLVED_ISSUES\""))
        #expect(output.contains("\"sub-u\""))
    }

    @Test func `no state filter passes nil to repo and lists all states`() async throws {
        let mockRepo = MockSubmissionRepository()
        given(mockRepo).listSubmissions(
            appId: .value("app-1"),
            states: .value(nil),
            limit: .any
        ).willReturn([])

        let cmd = try ReviewSubmissionsList.parse(["--app-id", "app-1"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("\"data\""))
    }
}
