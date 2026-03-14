import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite("SkillsUpdate")
struct SkillsUpdateTests {

    @Test func `update returns output from skills CLI`() async throws {
        let mockRepo = MockSkillRepository()
        given(mockRepo).update().willReturn("Updated 3 skills")

        let cmd = try SkillsUpdate.parse([])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == "Updated 3 skills")
    }
}
