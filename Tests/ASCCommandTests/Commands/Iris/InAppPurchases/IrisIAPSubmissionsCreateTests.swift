import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct IrisIAPSubmissionsCreateTests {

    @Test func `submitted IAP shows id, iap, and viewIAP affordance`() async throws {
        let mockCookieProvider = MockIrisCookieProvider()
        given(mockCookieProvider).resolveSession().willReturn(
            IrisSession(cookies: "myacinfo=test")
        )

        let mockRepo = MockIrisInAppPurchaseSubmissionRepository()
        given(mockRepo).submitInAppPurchase(
            session: .any, iapId: .any, submitWithNextAppStoreVersion: .any
        ).willReturn(
            IrisInAppPurchaseSubmission(
                id: "sub-9", iapId: "iap-7", submitWithNextAppStoreVersion: true
            )
        )

        let cmd = try IrisIAPSubmissionsCreate.parse(["--iap-id", "iap-7", "--pretty"])
        let output = try await cmd.execute(cookieProvider: mockCookieProvider, repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "viewIAP" : "asc iap get --iap-id iap-7"
              },
              "iapId" : "iap-7",
              "id" : "sub-9",
              "submitWithNextAppStoreVersion" : true
            }
          ]
        }
        """)
    }

    @Test func `--no-with-next-version disables the iris-only flag`() async throws {
        let mockCookieProvider = MockIrisCookieProvider()
        given(mockCookieProvider).resolveSession().willReturn(
            IrisSession(cookies: "myacinfo=test")
        )

        let mockRepo = MockIrisInAppPurchaseSubmissionRepository()
        given(mockRepo).submitInAppPurchase(
            session: .any, iapId: .any, submitWithNextAppStoreVersion: .value(false)
        ).willReturn(
            IrisInAppPurchaseSubmission(
                id: "sub-1", iapId: "iap-7", submitWithNextAppStoreVersion: false
            )
        )

        let cmd = try IrisIAPSubmissionsCreate.parse(["--iap-id", "iap-7", "--no-with-next-version"])
        _ = try await cmd.execute(cookieProvider: mockCookieProvider, repo: mockRepo)

        verify(mockRepo).submitInAppPurchase(
            session: .any, iapId: .value("iap-7"), submitWithNextAppStoreVersion: .value(false)
        ).called(1)
    }
}
