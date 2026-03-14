import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite("SkillsCheck")
struct SkillsCheckTests {

    @Test func `check shows up to date message`() async throws {
        let mockRepo = MockSkillRepository()
        let mockStorage = MockSkillConfigStorage()
        given(mockRepo).check().willReturn(.upToDate)
        given(mockStorage).load().willReturn(nil)
        given(mockStorage).save(.any).willReturn()

        let cmd = try SkillsCheck.parse([])
        let output = try await cmd.execute(repo: mockRepo, storage: mockStorage)

        #expect(output == "All skills are up to date.")
    }

    @Test func `check shows updates available message`() async throws {
        let mockRepo = MockSkillRepository()
        let mockStorage = MockSkillConfigStorage()
        given(mockRepo).check().willReturn(.updatesAvailable)
        given(mockStorage).load().willReturn(nil)
        given(mockStorage).save(.any).willReturn()

        let cmd = try SkillsCheck.parse([])
        let output = try await cmd.execute(repo: mockRepo, storage: mockStorage)

        #expect(output == "Skill updates are available. Run 'asc skills update' to refresh installed skills.")
    }

    @Test func `check shows unavailable message`() async throws {
        let mockRepo = MockSkillRepository()
        let mockStorage = MockSkillConfigStorage()
        given(mockRepo).check().willReturn(.unavailable)
        given(mockStorage).load().willReturn(nil)
        given(mockStorage).save(.any).willReturn()

        let cmd = try SkillsCheck.parse([])
        let output = try await cmd.execute(repo: mockRepo, storage: mockStorage)

        #expect(output == "Skills CLI is not available. Install with: npm install -g skills")
    }
}
