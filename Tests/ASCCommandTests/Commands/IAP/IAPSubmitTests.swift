import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct IAPSubmitTests {

    @Test func `submitted iap includes submission id, iapId and affordances`() async throws {
        let mockRepo = MockInAppPurchaseSubmissionRepository()
        given(mockRepo).submitInAppPurchase(iapId: .any)
            .willReturn(InAppPurchaseSubmission(id: "sub-1", iapId: "iap-1"))

        let cmd = try IAPSubmit.parse(["--iap-id", "iap-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listLocalizations" : "asc iap-localizations list --iap-id iap-1",
                "unsubmit" : "asc iap unsubmit --submission-id sub-1"
              },
              "iapId" : "iap-1",
              "id" : "sub-1"
            }
          ]
        }
        """)
    }
}
