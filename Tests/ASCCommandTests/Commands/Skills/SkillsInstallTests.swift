import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite("SkillsInstall")
struct SkillsInstallTests {

    @Test func `install specific skill by name`() async throws {
        let mockRepo = MockSkillRepository()
        given(mockRepo).install(name: .value("asc-cli")).willReturn("Installed asc-cli")

        let cmd = try SkillsInstall.parse(["--name", "asc-cli"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == "Installed asc-cli")
    }

    @Test func `install all skills when --all flag is used`() async throws {
        let mockRepo = MockSkillRepository()
        given(mockRepo).installAll().willReturn("Installed 5 skills")

        let cmd = try SkillsInstall.parse(["--all"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == "Installed 5 skills")
    }

    @Test func `install all skills when no flags provided`() async throws {
        let mockRepo = MockSkillRepository()
        given(mockRepo).installAll().willReturn("Installed all skills")

        let cmd = try SkillsInstall.parse([])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == "Installed all skills")
    }
}
