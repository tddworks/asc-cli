import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct IrisResolutionCenterGetTests {

    private func makeDetail(body: String) -> ResolutionCenterDetail {
        ResolutionCenterDetail(
            id: "thread-1",
            submissionId: "sub-1",
            threadState: "OPEN",
            messages: [
                ResolutionCenterMessage(
                    id: "msg-1",
                    threadId: "thread-1",
                    fromActor: "Apple",
                    body: body
                ),
            ],
            rejectionReasons: [
                ReviewRejectionReason(
                    id: "rej-1",
                    section: "Performance",
                    descriptionText: "App crashed on launch",
                    code: "2.1"
                ),
            ]
        )
    }

    @Test func `resolution details show reviewer message, rejection reasons, and back-link affordances`() async throws {
        let mockCookieProvider = MockIrisCookieProvider()
        given(mockCookieProvider).resolveSession().willReturn(IrisSession(cookies: "myacinfo=test"))

        let mockRepo = MockIrisResolutionCenterRepository()
        given(mockRepo).getResolution(session: .any, submissionId: .value("sub-1")).willReturn(
            makeDetail(body: "Guideline 2.1 - Performance")
        )

        let cmd = try IrisResolutionCenterGet.parse(["--submission-id", "sub-1", "--pretty"])
        let output = try await cmd.execute(cookieProvider: mockCookieProvider, repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "getSubmission" : "asc review-submissions get --submission-id sub-1",
                "listRejectedItems" : "asc review-submissions items list --state REJECTED --submission-id sub-1"
              },
              "id" : "thread-1",
              "messages" : [
                {
                  "body" : "Guideline 2.1 - Performance",
                  "fromActor" : "Apple",
                  "id" : "msg-1",
                  "threadId" : "thread-1"
                }
              ],
              "rejectionReasons" : [
                {
                  "code" : "2.1",
                  "descriptionText" : "App crashed on launch",
                  "id" : "rej-1",
                  "section" : "Performance"
                }
              ],
              "submissionId" : "sub-1",
              "threadState" : "OPEN"
            }
          ]
        }
        """)
    }

    @Test func `--plain-text converts html message bodies before output`() async throws {
        let mockCookieProvider = MockIrisCookieProvider()
        given(mockCookieProvider).resolveSession().willReturn(IrisSession(cookies: "myacinfo=test"))

        let mockRepo = MockIrisResolutionCenterRepository()
        given(mockRepo).getResolution(session: .any, submissionId: .value("sub-1")).willReturn(
            makeDetail(body: "<p>Guideline 2.1 &amp; 2.3<br/>We were unable to review.</p>")
        )

        let cmd = try IrisResolutionCenterGet.parse(["--submission-id", "sub-1", "--plain-text", "--pretty"])
        let output = try await cmd.execute(cookieProvider: mockCookieProvider, repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "getSubmission" : "asc review-submissions get --submission-id sub-1",
                "listRejectedItems" : "asc review-submissions items list --state REJECTED --submission-id sub-1"
              },
              "id" : "thread-1",
              "messages" : [
                {
                  "body" : "Guideline 2.1 & 2.3\\nWe were unable to review.",
                  "fromActor" : "Apple",
                  "id" : "msg-1",
                  "threadId" : "thread-1"
                }
              ],
              "rejectionReasons" : [
                {
                  "code" : "2.1",
                  "descriptionText" : "App crashed on launch",
                  "id" : "rej-1",
                  "section" : "Performance"
                }
              ],
              "submissionId" : "sub-1",
              "threadState" : "OPEN"
            }
          ]
        }
        """)
    }
}
