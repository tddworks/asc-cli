import Foundation
import Testing
@testable import ASCCommand
@testable import Domain

@Suite("SkillsUninstall")
struct SkillsUninstallTests {

    @Test func `uninstall removes skill directory`() async throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("asc-test-skills-\(UUID().uuidString)")
        let skillDir = dir.appendingPathComponent("asc-cli")
        try FileManager.default.createDirectory(at: skillDir, withIntermediateDirectories: true)
        try "test".write(to: skillDir.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)

        let cmd = try SkillsUninstall.parse(["--name", "asc-cli"])
        try await cmd.execute(skillsDirectory: dir)

        #expect(!FileManager.default.fileExists(atPath: skillDir.path))
    }

    @Test func `uninstall throws when skill not found`() async throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("asc-test-skills-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let cmd = try SkillsUninstall.parse(["--name", "nonexistent"])

        await #expect(throws: SkillError.self) {
            try await cmd.execute(skillsDirectory: dir)
        }
    }
}
