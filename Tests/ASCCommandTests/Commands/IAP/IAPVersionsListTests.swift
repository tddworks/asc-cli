import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct IAPVersionsListTests {

    @Test func `listed IAP versions show state and the command to add them to a submission`() async throws {
        let mockRepo = MockProductVersionRepository()
        given(mockRepo).listInAppPurchaseVersions(iapId: .value("iap-1")).willReturn([
            ProductVersion(id: "iv-1", productId: "iap-1", kind: .inAppPurchase, version: 1, state: .prepareForSubmission),
        ])

        let cmd = try IAPVersionsList.parse(["--iap-id", "iap-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "addToSubmission" : "asc review-submissions items add --iap-version-id iv-1 --submission-id <submission-id>",
                "listVersions" : "asc iap versions list --iap-id iap-1"
              },
              "id" : "iv-1",
              "kind" : "IN_APP_PURCHASE",
              "productId" : "iap-1",
              "state" : "PREPARE_FOR_SUBMISSION",
              "version" : 1
            }
          ]
        }
        """)
    }
}
