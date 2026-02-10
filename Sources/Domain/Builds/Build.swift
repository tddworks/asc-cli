import Foundation

public struct Build: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public let version: String
    public let uploadedDate: Date?
    public let expirationDate: Date?
    public let expired: Bool
    public let processingState: ProcessingState
    public let buildNumber: String?

    public init(
        id: String,
        version: String,
        uploadedDate: Date? = nil,
        expirationDate: Date? = nil,
        expired: Bool = false,
        processingState: ProcessingState = .valid,
        buildNumber: String? = nil
    ) {
        self.id = id
        self.version = version
        self.uploadedDate = uploadedDate
        self.expirationDate = expirationDate
        self.expired = expired
        self.processingState = processingState
        self.buildNumber = buildNumber
    }

    public var isUsable: Bool {
        !expired && processingState == .valid
    }

    public enum ProcessingState: String, Sendable, Codable {
        case processing = "PROCESSING"
        case failed = "FAILED"
        case invalid = "INVALID"
        case valid = "VALID"
    }
}
