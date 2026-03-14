import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite("SkillsList")
struct SkillsListTests {

    @Test func `list shows available skills from repo`() async throws {
        let mockRepo = MockSkillRepository()
        given(mockRepo).listAvailable().willReturn("asc-cli\nasc-auth\nasc-testflight")

        let cmd = try SkillsList.parse([])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == "asc-cli\nasc-auth\nasc-testflight")
    }
}
