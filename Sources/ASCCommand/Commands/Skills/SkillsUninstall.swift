import ArgumentParser
import Domain
import Foundation

struct SkillsUninstall: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "uninstall",
        abstract: "Remove an installed skill"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Skill name to uninstall")
    var name: String

    func run() async throws {
        try await execute()
    }

    func execute(skillsDirectory: URL = Self.defaultSkillsDirectory) async throws {
        let skillDir = skillsDirectory.appendingPathComponent(name)
        guard FileManager.default.fileExists(atPath: skillDir.path) else {
            throw SkillError.notFound(name: name)
        }
        try FileManager.default.removeItem(at: skillDir)
        print("Skill '\(name)' uninstalled.")
    }

    static var defaultSkillsDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude")
            .appendingPathComponent("skills")
    }
}

enum SkillError: Error, LocalizedError {
    case notFound(name: String)

    var errorDescription: String? {
        switch self {
        case .notFound(let name):
            return "Skill '\(name)' not found in ~/.claude/skills/"
        }
    }
}
