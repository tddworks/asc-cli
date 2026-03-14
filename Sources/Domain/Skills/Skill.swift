/// A Claude Code skill that can be installed from the asc-cli skills repository.
///
/// Skills are discovered via `npx skills add tddworks/asc-cli --list`
/// and installed to `~/.claude/skills/` for agent use.
public struct Skill: Sendable, Equatable, Identifiable, Codable {
    public let id: String           // = name
    public let name: String
    public let description: String
    public let isInstalled: Bool

    public init(
        id: String,
        name: String,
        description: String,
        isInstalled: Bool
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.isInstalled = isInstalled
    }
}

extension Skill: AffordanceProviding {
    public var affordances: [String: String] {
        var cmds: [String: String] = [
            "listSkills": "asc skills list",
        ]
        if isInstalled {
            cmds["uninstall"] = "asc skills uninstall --name \(name)"
        } else {
            cmds["install"] = "asc skills install --name \(name)"
        }
        return cmds
    }
}
