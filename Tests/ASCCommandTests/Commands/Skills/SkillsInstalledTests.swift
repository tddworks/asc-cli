import Foundation
import Testing
@testable import ASCCommand
@testable import Domain

@Suite("SkillsInstalled")
struct SkillsInstalledTests {

    private func makeTempSkillsDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("asc-test-skills-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func createSkillDir(in parent: URL, name: String, description: String) throws {
        let skillDir = parent.appendingPathComponent(name)
        try FileManager.default.createDirectory(at: skillDir, withIntermediateDirectories: true)
        let skillMD = """
        ---
        name: \(name)
        description: |
          \(description)
        ---
        # \(name)
        """
        try skillMD.write(to: skillDir.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)
    }

    @Test func `installed lists skills with affordances`() async throws {
        let dir = try makeTempSkillsDir()
        try createSkillDir(in: dir, name: "asc-cli", description: "App Store Connect CLI skill")

        let cmd = try SkillsInstalled.parse(["--pretty"])
        let output = try await cmd.execute(skillsDirectory: dir)

        #expect(output.contains("\"name\" : \"asc-cli\""))
        #expect(output.contains("\"isInstalled\" : true"))
        #expect(output.contains("\"uninstall\" : \"asc skills uninstall --name asc-cli\""))
    }

    @Test func `installed returns empty data when no skills`() async throws {
        let dir = try makeTempSkillsDir()

        let cmd = try SkillsInstalled.parse(["--pretty"])
        let output = try await cmd.execute(skillsDirectory: dir)

        #expect(output == """
        {
          "data" : [

          ]
        }
        """)
    }

    @Test func `installed returns empty data when directory does not exist`() async throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("nonexistent-\(UUID().uuidString)")

        let cmd = try SkillsInstalled.parse(["--pretty"])
        let output = try await cmd.execute(skillsDirectory: dir)

        #expect(output == """
        {
          "data" : [

          ]
        }
        """)
    }
}
