import Domain
import Foundation

/// Non-blocking auto-update checker called on every `asc` command.
///
/// Guard rails:
/// - `ASC_SKIP_SKILL_CHECK=true` → skip
/// - CI env var set → skip
/// - Last check < 24h ago → skip
///
/// Failures are silently swallowed — never interrupts normal CLI flow.
enum SkillUpdateChecker {

    static let checkInterval: TimeInterval = 24 * 60 * 60 // 24 hours

    static func checkIfNeeded(
        repo: any SkillRepository,
        storage: any SkillConfigStorage,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        now: Date = Date()
    ) async {
        // Guard: disabled by env var
        if environment["ASC_SKIP_SKILL_CHECK"]?.lowercased() == "true" {
            return
        }

        // Guard: CI environment
        if environment["CI"] != nil || environment["CONTINUOUS_INTEGRATION"] != nil {
            return
        }

        // Guard: cooldown — last check < 24h ago
        if let config = try? await storage.load(),
           let lastCheck = config.skillsCheckedAt,
           now.timeIntervalSince(lastCheck) < checkInterval {
            return
        }

        // Run the check
        let result = try? await repo.check()

        // Persist timestamp (except when unavailable)
        if result != nil && result != .unavailable {
            var config = (try? await storage.load()) ?? SkillConfig()
            config.skillsCheckedAt = now
            try? await storage.save(config)
        }

        // Notify on stderr (non-blocking)
        if result == .updatesAvailable {
            FileHandle.standardError.write(
                Data("Skill updates available. Run 'asc skills update' to refresh installed skills.\n".utf8)
            )
        }
    }
}
