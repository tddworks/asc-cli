import Foundation

public struct Build: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public let version: String
    public let uploadedDate: Date?
    public let expirationDate: Date?
    public let expired: Bool
    public let processingState: ProcessingState
    public let buildNumber: String?
    public let platform: BuildUploadPlatform?

    public init(
        id: String,
        version: String,
        uploadedDate: Date? = nil,
        expirationDate: Date? = nil,
        expired: Bool = false,
        processingState: ProcessingState = .valid,
        buildNumber: String? = nil,
        platform: BuildUploadPlatform? = nil
    ) {
        self.id = id
        self.version = version
        self.uploadedDate = uploadedDate
        self.expirationDate = expirationDate
        self.expired = expired
        self.processingState = processingState
        self.buildNumber = buildNumber
        self.platform = platform
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

extension Build: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Version", "Build Number", "Platform", "State", "Expired"]
    }
    public var tableRow: [String] {
        [id, version, buildNumber ?? "-", platform?.rawValue ?? "-", processingState.rawValue, expired ? "Yes" : "No"]
    }
}

extension Build: AffordanceProviding {
    public var affordances: [String: String] {
        guard isUsable else { return [:] }
        return [
            "addToTestFlight": "asc builds add-beta-group --build-id \(id) --beta-group-id <beta-group-id>",
            "updateBetaNotes": "asc builds update-beta-notes --build-id \(id) --locale en-US --notes <notes>"
        ]
    }
}
