import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct IAPDeleteTests {

    @Test func `delete iap calls repo with iap id`() async throws {
        let mockRepo = MockInAppPurchaseRepository()
        given(mockRepo).deleteInAppPurchase(iapId: .any).willReturn(())

        let cmd = try IAPDelete.parse(["--iap-id", "iap-1"])
        try await cmd.execute(repo: mockRepo)

        verify(mockRepo).deleteInAppPurchase(iapId: .value("iap-1")).called(1)
    }
}
