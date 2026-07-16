import Foundation

/// A file App Review (or the developer) attached to a Resolution Center
/// message — typically a screenshot showing the issue. Downloads go through
/// Apple-signed URLs; `isValidDownloadURL` gates which hosts we will fetch.
public struct ResolutionCenterAttachment: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    /// Parent message — iris responses omit it; Infrastructure injects it.
    public let messageId: String
    public let fileName: String
    public let fileSize: Int?
    /// Apple-signed download URL. Absent while the asset is still processing.
    public let downloadUrl: String?

    public init(
        id: String,
        messageId: String,
        fileName: String,
        fileSize: Int? = nil,
        downloadUrl: String? = nil
    ) {
        self.id = id
        self.messageId = messageId
        self.fileName = fileName
        self.fileSize = fileSize
        self.downloadUrl = downloadUrl
    }

    public var isDownloadable: Bool { !(downloadUrl ?? "").isEmpty }

    /// Signed attachment URLs must be https on Apple's own hosts or the CDNs
    /// Apple delivers assets through — anything else is refused.
    public static func isValidDownloadURL(_ raw: String) -> Bool {
        guard let url = URL(string: raw),
              url.scheme?.lowercased() == "https",
              let host = url.host?.lowercased() else { return false }
        let allowedSuffixes = [".apple.com", ".mzstatic.com", ".amazonaws.com", ".cloudfront.net"]
        return allowedSuffixes.contains { host.hasSuffix($0) }
    }
}

// MARK: - Codable (omit nil optional fields from JSON output)

extension ResolutionCenterAttachment {
    enum CodingKeys: String, CodingKey {
        case id, messageId, fileName, fileSize, downloadUrl
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        messageId = try c.decode(String.self, forKey: .messageId)
        fileName = try c.decode(String.self, forKey: .fileName)
        fileSize = try c.decodeIfPresent(Int.self, forKey: .fileSize)
        downloadUrl = try c.decodeIfPresent(String.self, forKey: .downloadUrl)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(messageId, forKey: .messageId)
        try c.encode(fileName, forKey: .fileName)
        try c.encodeIfPresent(fileSize, forKey: .fileSize)
        try c.encodeIfPresent(downloadUrl, forKey: .downloadUrl)
    }
}
