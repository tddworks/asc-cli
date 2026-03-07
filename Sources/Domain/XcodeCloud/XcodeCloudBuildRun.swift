import Foundation

public enum XcodeCloudBuildRunExecutionProgress: String, Sendable, Equatable, Codable {
    case pending = "PENDING"
    case running = "RUNNING"
    case complete = "COMPLETE"

    public var isPending: Bool { self == .pending }
    public var isRunning: Bool { self == .running }
    public var isComplete: Bool { self == .complete }
}

public enum XcodeCloudBuildRunCompletionStatus: String, Sendable, Equatable, Codable {
    case succeeded = "SUCCEEDED"
    case failed = "FAILED"
    case errored = "ERRORED"
    case canceled = "CANCELED"
    case skipped = "SKIPPED"

    public var isSucceeded: Bool { self == .succeeded }
    public var hasFailed: Bool { self == .failed || self == .errored }
}

public enum XcodeCloudBuildRunStartReason: String, Sendable, Equatable, Codable {
    case gitRefChange = "GIT_REF_CHANGE"
    case manual = "MANUAL"
    case manualRebuild = "MANUAL_REBUILD"
    case pullRequestOpen = "PULL_REQUEST_OPEN"
    case pullRequestUpdate = "PULL_REQUEST_UPDATE"
    case schedule = "SCHEDULE"
}

public struct XcodeCloudBuildRun: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let workflowId: String
    public let number: Int?
    public let executionProgress: XcodeCloudBuildRunExecutionProgress
    public let completionStatus: XcodeCloudBuildRunCompletionStatus?
    public let startReason: XcodeCloudBuildRunStartReason?
    public let createdDate: Date?
    public let startedDate: Date?
    public let finishedDate: Date?

    public init(
        id: String, workflowId: String,
        number: Int? = nil,
        executionProgress: XcodeCloudBuildRunExecutionProgress,
        completionStatus: XcodeCloudBuildRunCompletionStatus? = nil,
        startReason: XcodeCloudBuildRunStartReason? = nil,
        createdDate: Date? = nil,
        startedDate: Date? = nil,
        finishedDate: Date? = nil
    ) {
        self.id = id
        self.workflowId = workflowId
        self.number = number
        self.executionProgress = executionProgress
        self.completionStatus = completionStatus
        self.startReason = startReason
        self.createdDate = createdDate
        self.startedDate = startedDate
        self.finishedDate = finishedDate
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.workflowId = try container.decode(String.self, forKey: .workflowId)
        self.number = try container.decodeIfPresent(Int.self, forKey: .number)
        self.executionProgress = try container.decode(XcodeCloudBuildRunExecutionProgress.self, forKey: .executionProgress)
        self.completionStatus = try container.decodeIfPresent(XcodeCloudBuildRunCompletionStatus.self, forKey: .completionStatus)
        self.startReason = try container.decodeIfPresent(XcodeCloudBuildRunStartReason.self, forKey: .startReason)
        self.createdDate = try container.decodeIfPresent(Date.self, forKey: .createdDate)
        self.startedDate = try container.decodeIfPresent(Date.self, forKey: .startedDate)
        self.finishedDate = try container.decodeIfPresent(Date.self, forKey: .finishedDate)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(workflowId, forKey: .workflowId)
        try container.encodeIfPresent(number, forKey: .number)
        try container.encode(executionProgress, forKey: .executionProgress)
        try container.encodeIfPresent(completionStatus, forKey: .completionStatus)
        try container.encodeIfPresent(startReason, forKey: .startReason)
        try container.encodeIfPresent(createdDate, forKey: .createdDate)
        try container.encodeIfPresent(startedDate, forKey: .startedDate)
        try container.encodeIfPresent(finishedDate, forKey: .finishedDate)
    }

    private enum CodingKeys: String, CodingKey {
        case id, workflowId, number, executionProgress, completionStatus, startReason
        case createdDate, startedDate, finishedDate
    }
}

extension XcodeCloudBuildRun: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "getBuildRun": "asc xcode-cloud builds get --build-run-id \(id)",
            "listBuildRuns": "asc xcode-cloud builds list --workflow-id \(workflowId)",
        ]
    }
}
