import Mockable

/// Manages skill installation, updates, and discovery via the skills CLI.
@Mockable
public protocol SkillRepository: Sendable {
    /// List available skills from the repository.
    func listAvailable() async throws -> String

    /// Install a specific skill by name.
    func install(name: String) async throws -> String

    /// Install all available skills.
    func installAll() async throws -> String

    /// Check for skill updates.
    func check() async throws -> SkillCheckResult

    /// Update installed skills.
    func update() async throws -> String
}
