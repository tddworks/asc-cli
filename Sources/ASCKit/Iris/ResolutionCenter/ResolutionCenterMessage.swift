import Foundation

/// One message in a Resolution Center thread — this is where App Review's
/// actual rejection text lives. The official App Store Connect API has no
/// endpoint for it; it is only reachable through the iris private API.
public struct ResolutionCenterMessage: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    /// Parent thread — iris responses omit it; Infrastructure injects it.
    public let threadId: String
    public let createdDate: Date?
    /// Who wrote the message (e.g. Apple's review team vs. the developer).
    public let fromActor: String?
    /// Message body as returned by iris (HTML). Use `plainTextBody` or
    /// `ResolutionCenterDetail.plainText()` for terminal-friendly output.
    public let body: String

    public init(
        id: String,
        threadId: String,
        createdDate: Date? = nil,
        fromActor: String? = nil,
        body: String
    ) {
        self.id = id
        self.threadId = threadId
        self.createdDate = createdDate
        self.fromActor = fromActor
        self.body = body
    }

    /// `body` with HTML tags stripped and entities unescaped.
    public var plainTextBody: String {
        Self.htmlToPlainText(body)
    }

    static func htmlToPlainText(_ html: String) -> String {
        var text = html
        // Line-breaking elements become newlines before tags are stripped.
        text = text.replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: [.regularExpression, .caseInsensitive])
        text = text.replacingOccurrences(of: "</p>", with: "\n", options: [.caseInsensitive])
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        let entities: [(String, String)] = [
            ("&nbsp;", " "), ("&lt;", "<"), ("&gt;", ">"),
            ("&quot;", "\""), ("&#39;", "'"), ("&amp;", "&"),
        ]
        for (entity, character) in entities {
            text = text.replacingOccurrences(of: entity, with: character)
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Codable (omit nil optional fields from JSON output)

extension ResolutionCenterMessage {
    enum CodingKeys: String, CodingKey {
        case id, threadId, createdDate, fromActor, body
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        threadId = try c.decode(String.self, forKey: .threadId)
        createdDate = try c.decodeIfPresent(Date.self, forKey: .createdDate)
        fromActor = try c.decodeIfPresent(String.self, forKey: .fromActor)
        body = try c.decode(String.self, forKey: .body)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(threadId, forKey: .threadId)
        try c.encodeIfPresent(createdDate, forKey: .createdDate)
        try c.encodeIfPresent(fromActor, forKey: .fromActor)
        try c.encode(body, forKey: .body)
    }
}
