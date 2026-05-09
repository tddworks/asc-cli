import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct BetaAppLocalizationsDeleteTests {

    @Test func `delete beta app localization calls repo with localization id`() async throws {
        let mockRepo = MockBetaAppLocalizationRepository()
        given(mockRepo).deleteBetaAppLocalization(localizationId: .any).willReturn(())

        let cmd = try BetaAppLocalizationsDelete.parse(["--localization-id", "bal-1"])
        try await cmd.execute(repo: mockRepo)

        verify(mockRepo).deleteBetaAppLocalization(localizationId: .value("bal-1")).called(1)
    }
}
