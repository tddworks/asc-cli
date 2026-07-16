import Foundation

/// The Resolution Center conversation for one review submission: the thread,
/// its messages (App Review's rejection text), and the structured rejection
/// reasons. Composed by Infrastructure from three iris calls; the official
/// App Store Connect API cannot produce this data.
public struct ResolutionCenterDetail: Sendable, Equatable, Identifiable, Codable {
    /// Thread identifier.
    public let id: String
    /// Parent review submission — iris responses omit it; Infrastructure injects it.
    public let submissionId: String
    public let threadState: String?
    public let messages: [ResolutionCenterMessage]
    public let rejectionReasons: [ReviewRejectionReason]
    public let attachments: [ResolutionCenterAttachment]

    public init(
        id: String,
        submissionId: String,
        threadState: String? = nil,
        messages: [ResolutionCenterMessage] = [],
        rejectionReasons: [ReviewRejectionReason] = [],
        attachments: [ResolutionCenterAttachment] = []
    ) {
        self.id = id
        self.submissionId = submissionId
        self.threadState = threadState
        self.messages = messages
        self.rejectionReasons = rejectionReasons
        self.attachments = attachments
    }

    /// Apple attached at least one structured guideline citation.
    public var hasRejections: Bool { !rejectionReasons.isEmpty }

    /// A copy with every message body converted from HTML to plain text.
    public func plainText() -> ResolutionCenterDetail {
        ResolutionCenterDetail(
            id: id,
            submissionId: submissionId,
            threadState: threadState,
            messages: messages.map {
                ResolutionCenterMessage(
                    id: $0.id,
                    threadId: $0.threadId,
                    createdDate: $0.createdDate,
                    fromActor: $0.fromActor,
                    body: $0.plainTextBody
                )
            },
            rejectionReasons: rejectionReasons,
            attachments: attachments
        )
    }
}

// MARK: - Codable (omit nil optional fields from JSON output)

extension ResolutionCenterDetail {
    enum CodingKeys: String, CodingKey {
        case id, submissionId, threadState, messages, rejectionReasons, attachments
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        submissionId = try c.decode(String.self, forKey: .submissionId)
        threadState = try c.decodeIfPresent(String.self, forKey: .threadState)
        messages = try c.decode([ResolutionCenterMessage].self, forKey: .messages)
        rejectionReasons = try c.decode([ReviewRejectionReason].self, forKey: .rejectionReasons)
        attachments = try c.decodeIfPresent([ResolutionCenterAttachment].self, forKey: .attachments) ?? []
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(submissionId, forKey: .submissionId)
        try c.encodeIfPresent(threadState, forKey: .threadState)
        try c.encode(messages, forKey: .messages)
        try c.encode(rejectionReasons, forKey: .rejectionReasons)
        if !attachments.isEmpty {
            try c.encode(attachments, forKey: .attachments)
        }
    }
}

extension ResolutionCenterDetail: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        var items: [Affordance] = [
            Affordance(key: "getSubmission", command: "review-submissions", action: "get",
                       params: ["submission-id": submissionId]),
            Affordance(key: "listRejectedItems", command: "review-submissions items", action: "list",
                       params: ["submission-id": submissionId, "state": "REJECTED"]),
        ]
        if !attachments.isEmpty {
            items.append(Affordance(key: "downloadAttachments", command: "iris resolution-center", action: "get",
                                    params: ["submission-id": submissionId, "out": "<dir>"]))
        }
        return items
    }
}

extension ResolutionCenterDetail: Presentable {
    public static var tableHeaders: [String] {
        ["Thread ID", "Submission ID", "State", "Messages", "Rejections"]
    }
    public var tableRow: [String] {
        [id, submissionId, threadState ?? "-", "\(messages.count)", "\(rejectionReasons.count)"]
    }
}
