import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct AppInfoLocalizationsDeleteTests {

    @Test func `delete calls repository and prints deleted id`() async throws {
        let mockRepo = MockAppInfos()
        given(mockRepo)
            .deleteLocalization(id: .any)
            .willReturn(())

        let cmd = try AppInfoLocalizationsDelete.parse([
            "--localization-id", "loc-42",
        ])
        try await cmd.execute(repo: mockRepo)
    }
}
