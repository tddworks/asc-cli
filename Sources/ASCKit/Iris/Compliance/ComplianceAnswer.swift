/// The developer's answer to a requirement's question ("Does your app offer AIGC
/// services in China mainland?"). A No carries nothing (law 3).
public enum ComplianceAnswer: Sendable, Equatable {
    /// The app doesn't offer the regulated feature in the region, or it's disabled or geoblocked there.
    case notOffered

    /// The question's option, as Apple's form names it.
    var wireValue: String {
        switch self {
        case .notOffered: "NO"
        }
    }
}

/// An answer Apple holds for a requirement. Apple's API calls it a *form*.
/// The evidence of a Yes stays with Apple; the list shows only the answer.
public struct ComplianceDeclaration: Sendable, Equatable, Codable {
    public enum Answer: String, Sendable, Equatable, Codable {
        case yes = "YES"
        case no = "NO"
    }

    /// Apple's form id: what a change updates.
    public let id: String
    public let answer: Answer

    public init(id: String, answer: Answer) {
        self.id = id
        self.answer = answer
    }
}
