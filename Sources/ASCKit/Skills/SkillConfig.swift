import Foundation

/// Persisted skill management configuration.
///
/// Stored at `~/.asc/skills-config.json`. Tracks when the last
/// update check was performed to enforce the 24-hour cooldown.
public struct SkillConfig: Sendable, Equatable, Codable {
    public var skillsCheckedAt: Date?

    public init(skillsCheckedAt: Date? = nil) {
        self.skillsCheckedAt = skillsCheckedAt
    }
}

extension SkillConfig {
    enum CodingKeys: String, CodingKey {
        case skillsCheckedAt
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        skillsCheckedAt = try c.decodeIfPresent(Date.self, forKey: .skillsCheckedAt)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(skillsCheckedAt, forKey: .skillsCheckedAt)
    }
}
