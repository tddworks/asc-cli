import Foundation

/// Manages skills by shelling out to the `skills` CLI or `npx`.
///
/// Strategy A: Find `skills` binary on PATH (skip if inside current git repo).
/// Strategy B: Fallback to `npx --yes skills ...`.
public struct ProcessSkills: Skills {

    private static let repoSlug = "tddworks/asc-cli-skills"
    private let runner: any ShellRunner

    public init(runner: any ShellRunner = SystemShellRunner()) {
        self.runner = runner
    }

    public func listAvailable() async throws -> String {
        try await runSkillsCommand(["add", Self.repoSlug, "--list"])
    }

    public func install(name: String) async throws -> String {
        try await runSkillsCommand(["add", Self.repoSlug, "--yes", "--name", name])
    }

    public func installAll() async throws -> String {
        try await runSkillsCommand(["add", Self.repoSlug, "--yes"])
    }

    public func check() async throws -> SkillCheckResult {
        do {
            let output = try await runSkillsCommand(["check"])
            return parseCheckOutput(output)
        } catch {
            return .unavailable
        }
    }

    public func update() async throws -> String {
        try await runSkillsCommand(["add", Self.repoSlug, "--yes"])
    }

    // MARK: - Private

    private func runSkillsCommand(_ arguments: [String]) async throws -> String {
        try await runner.run(
            command: "npx",
            arguments: ["--yes", "skills"] + arguments,
            environment: nil
        )
    }

    private func parseCheckOutput(_ output: String) -> SkillCheckResult {
        let lower = output.lowercased()
        // Check "no update" first — "no updates available" should be upToDate
        if lower.contains("all skills are up to date") || lower.contains("no update") {
            return .upToDate
        }
        if lower.contains("update") && lower.contains("available") {
            return .updatesAvailable
        }
        return .upToDate
    }
}
