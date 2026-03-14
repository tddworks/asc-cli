/// The outcome of checking for skill updates.
public enum SkillCheckResult: String, Sendable, Equatable, Codable {
    case upToDate
    case updatesAvailable
    case unavailable
}
