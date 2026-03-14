import ArgumentParser
import Domain
import Foundation

struct SkillsInstalled: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "installed",
        abstract: "Show skills installed in ~/.claude/skills/"
    )

    @OptionGroup var globals: GlobalOptions

    func run() async throws {
        print(try await execute())
    }

    func execute(skillsDirectory: URL = Self.defaultSkillsDirectory) async throws -> String {
        let skills = try loadInstalledSkills(from: skillsDirectory)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            skills,
            headers: ["Name", "Description"],
            rowMapper: { [$0.name, $0.description] }
        )
    }

    private func loadInstalledSkills(from directory: URL) throws -> [Skill] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: directory.path) else { return [] }

        let entries = try fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: .skipsHiddenFiles
        )

        return entries
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
            .compactMap { dir -> Skill? in
                let skillMD = dir.appendingPathComponent("SKILL.md")
                guard fm.fileExists(atPath: skillMD.path) else { return nil }
                let frontmatter = parseFrontmatter(at: skillMD)
                return Skill(
                    id: frontmatter.name ?? dir.lastPathComponent,
                    name: frontmatter.name ?? dir.lastPathComponent,
                    description: frontmatter.description ?? "",
                    isInstalled: true
                )
            }
            .sorted { $0.name < $1.name }
    }

    private func parseFrontmatter(at url: URL) -> (name: String?, description: String?) {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            return (nil, nil)
        }

        let lines = content.components(separatedBy: .newlines)
        guard lines.first == "---" else { return (nil, nil) }

        var name: String?
        var description: String?

        for line in lines.dropFirst() {
            if line == "---" { break }
            if line.hasPrefix("name:") {
                name = line.replacingOccurrences(of: "name:", with: "").trimmingCharacters(in: .whitespaces)
            }
            if line.hasPrefix("description:") {
                let value = line.replacingOccurrences(of: "description:", with: "").trimmingCharacters(in: .whitespaces)
                if !value.isEmpty && value != "|" {
                    description = value
                } else {
                    // Multi-line description — take the first non-empty indented line
                    let remaining = lines.drop(while: { $0 != line }).dropFirst()
                    for nextLine in remaining {
                        if nextLine == "---" { break }
                        let trimmed = nextLine.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty && !trimmed.hasPrefix("name:") {
                            description = trimmed
                            break
                        }
                    }
                }
            }
        }

        return (name, description)
    }

    static var defaultSkillsDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude")
            .appendingPathComponent("skills")
    }
}
