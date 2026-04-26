import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct IAPLocalizationsDeleteTests {

    @Test func `delete localization calls repo with localization id`() async throws {
        let mockRepo = MockInAppPurchaseLocalizationRepository()
        given(mockRepo).deleteLocalization(localizationId: .any).willReturn(())

        let cmd = try IAPLocalizationsDelete.parse(["--localization-id", "loc-1"])
        try await cmd.execute(repo: mockRepo)

        verify(mockRepo).deleteLocalization(localizationId: .value("loc-1")).called(1)
    }
}
