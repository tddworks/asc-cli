import Mockable

/// Persists skill management configuration to `~/.asc/skills-config.json`.
@Mockable
public protocol SkillConfigStorage: Sendable {
    func load() async throws -> SkillConfig?
    func save(_ config: SkillConfig) async throws
}
