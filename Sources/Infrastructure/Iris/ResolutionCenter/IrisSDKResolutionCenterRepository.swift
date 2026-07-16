import Domain
import Foundation

/// Implements `IrisResolutionCenterRepository` via the iris private API.
///
/// The Resolution Center (App Review's rejection message text and guideline
/// citations) has no official App Store Connect API surface — Apple's OpenAPI
/// spec contains no `resolutionCenter*` or `reviewRejection*` paths. The web
/// UI reads it from these three iris endpoints, composed here into one
/// user-visible operation. The endpoint shapes are undocumented; this mapper
/// is the absorption layer if Apple shifts a field.
public struct IrisSDKResolutionCenterRepository: IrisResolutionCenterRepository, @unchecked Sendable {
    private let client: IrisClient

    public init(client: IrisClient = IrisClient()) {
        self.client = client
    }

    public func getResolution(
        session: IrisSession,
        submissionId: String
    ) async throws -> Domain.ResolutionCenterDetail {
        let (threadsData, _) = try await client.get(
            path: "resolutionCenterThreads",
            queryItems: [URLQueryItem(name: "filter[reviewSubmission]", value: submissionId)],
            cookies: session.cookies
        )
        let threads = try decode(IrisThreadsResponse.self, from: threadsData)
        guard let thread = threads.data.first else {
            throw IrisResolutionCenterError.noThread(submissionId: submissionId)
        }

        async let messagesResult = client.get(
            path: "resolutionCenterThreads/\(thread.id)/resolutionCenterMessages",
            queryItems: [
                URLQueryItem(name: "include", value: "fromActor,rejections,resolutionCenterMessageAttachments"),
                URLQueryItem(name: "limit", value: "200"),
                URLQueryItem(name: "limit[resolutionCenterMessageAttachments]", value: "1000"),
            ],
            cookies: session.cookies
        )
        async let rejectionsResult = client.get(
            path: "reviewRejections",
            queryItems: [
                URLQueryItem(name: "filter[resolutionCenterMessage.resolutionCenterThread]", value: thread.id),
                URLQueryItem(name: "limit", value: "200"),
            ],
            cookies: session.cookies
        )
        let ((messagesData, _), (rejectionsData, _)) = try await (messagesResult, rejectionsResult)

        let messages = try decode(IrisMessagesResponse.self, from: messagesData)
        let rejections = try decode(IrisRejectionsResponse.self, from: rejectionsData)

        // Index included actors so fromActor resolves to a readable label.
        let actorsById: [String: IrisIncludedResource] = Dictionary(
            uniqueKeysWithValues: (messages.included ?? [])
                .filter { $0.type == "actors" }
                .map { ($0.id, $0) }
        )
        let attachmentsById: [String: IrisIncludedResource] = Dictionary(
            uniqueKeysWithValues: (messages.included ?? [])
                .filter { $0.type == "resolutionCenterMessageAttachments" }
                .map { ($0.id, $0) }
        )
        let attachments: [Domain.ResolutionCenterAttachment] = messages.data.flatMap { message in
            (message.relationships?.resolutionCenterMessageAttachments?.data ?? []).compactMap { ref in
                guard let included = attachmentsById[ref.id] else { return nil }
                return Domain.ResolutionCenterAttachment(
                    id: ref.id,
                    messageId: message.id,
                    fileName: included.attributes?.fileName ?? ref.id,
                    fileSize: included.attributes?.fileSize,
                    downloadUrl: included.attributes?.downloadUrl
                )
            }
        }

        return Domain.ResolutionCenterDetail(
            id: thread.id,
            submissionId: submissionId,
            threadState: thread.attributes?.state,
            messages: messages.data.map { message in
                let actorId = message.relationships?.fromActor?.data?.id
                let actor = actorId.flatMap { actorsById[$0] }
                return Domain.ResolutionCenterMessage(
                    id: message.id,
                    threadId: thread.id,
                    createdDate: message.attributes?.createdDate.flatMap(Self.parseDate),
                    fromActor: actor?.attributes?.actorType ?? actor?.attributes?.name,
                    body: message.attributes?.messageBody ?? ""
                )
            },
            rejectionReasons: rejections.data.flatMap { rejection in
                let reasons = rejection.attributes?.reasons ?? []
                return reasons.enumerated().map { index, reason in
                    Domain.ReviewRejectionReason(
                        id: reasons.count > 1 ? "\(rejection.id)-\(index)" : rejection.id,
                        section: reason.reasonSection,
                        descriptionText: reason.reasonDescription,
                        code: reason.reasonCode
                    )
                }
            },
            attachments: attachments
        )
    }

    public func downloadAttachment(
        session: IrisSession,
        url: String
    ) async throws -> Data {
        guard Domain.ResolutionCenterAttachment.isValidDownloadURL(url),
              let downloadURL = URL(string: url) else {
            throw IrisResolutionCenterError.invalidAttachmentURL(url)
        }
        let (data, _) = try await client.download(absoluteURL: downloadURL, cookies: session.cookies)
        return data
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw IrisAPIError.decodingError("\(error)")
        }
    }

    private static func parseDate(_ raw: String) -> Date? {
        // Iris timestamps come as ISO8601, sometimes with fractional seconds.
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFraction.date(from: raw) { return date }
        return ISO8601DateFormatter().date(from: raw)
    }
}

/// Resolution Center read/download failures with actionable messages.
public enum IrisResolutionCenterError: LocalizedError, Equatable {
    case noThread(submissionId: String)
    case invalidAttachmentURL(String)

    public var errorDescription: String? {
        switch self {
        case .noThread(let submissionId):
            "No Resolution Center thread found for submission \(submissionId). "
                + "App Review has not sent any messages for this submission yet."
        case .invalidAttachmentURL(let url):
            "Refusing to download attachment from '\(url)' — only https URLs on "
                + "Apple hosts (.apple.com, .mzstatic.com, .amazonaws.com, .cloudfront.net) are allowed."
        }
    }
}

// MARK: - Iris JSON:API response shapes (undocumented; tolerant decoding)

private struct IrisThreadsResponse: Decodable {
    struct Thread: Decodable {
        struct Attributes: Decodable {
            let state: String?
        }
        let id: String
        let attributes: Attributes?
    }
    let data: [Thread]
}

private struct IrisMessagesResponse: Decodable {
    struct Message: Decodable {
        struct Attributes: Decodable {
            let messageBody: String?
            let createdDate: String?
        }
        struct Relationships: Decodable {
            struct Ref: Decodable {
                let id: String
            }
            struct Relationship: Decodable {
                let data: Ref?
            }
            struct RelationshipList: Decodable {
                let data: [Ref]?
            }
            let fromActor: Relationship?
            let resolutionCenterMessageAttachments: RelationshipList?
        }
        let id: String
        let attributes: Attributes?
        let relationships: Relationships?
    }
    let data: [Message]
    let included: [IrisIncludedResource]?
}

private struct IrisIncludedResource: Decodable {
    struct Attributes: Decodable {
        let actorType: String?
        let name: String?
        let fileName: String?
        let fileSize: Int?
        let downloadUrl: String?
    }
    let type: String
    let id: String
    let attributes: Attributes?
}

private struct IrisRejectionsResponse: Decodable {
    struct Rejection: Decodable {
        struct Attributes: Decodable {
            let reasons: [Reason]?
        }
        struct Reason: Decodable {
            let reasonSection: String?
            let reasonDescription: String?
            let reasonCode: String?
        }
        let id: String
        let attributes: Attributes?
    }
    let data: [Rejection]
}
