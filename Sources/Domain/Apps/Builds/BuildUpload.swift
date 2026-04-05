import Foundation

public struct BuildUploadStateDetail: Sendable, Equatable, Codable {
    public let code: String
    public let description: String

    public init(code: String, description: String) {
        self.code = code
        self.description = description
    }
}

public struct BuildUpload: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let appId: String
    public let version: String
    public let buildNumber: String
    public let platform: BuildUploadPlatform
    public let state: BuildUploadState
    public let createdDate: Date?
    public let uploadedDate: Date?
    public let errors: [BuildUploadStateDetail]
    public let warnings: [BuildUploadStateDetail]
    public let infos: [BuildUploadStateDetail]

    public init(
        id: String,
        appId: String,
        version: String,
        buildNumber: String,
        platform: BuildUploadPlatform,
        state: BuildUploadState,
        createdDate: Date? = nil,
        uploadedDate: Date? = nil,
        errors: [BuildUploadStateDetail] = [],
        warnings: [BuildUploadStateDetail] = [],
        infos: [BuildUploadStateDetail] = []
    ) {
        self.id = id
        self.appId = appId
        self.version = version
        self.buildNumber = buildNumber
        self.platform = platform
        self.state = state
        self.createdDate = createdDate
        self.uploadedDate = uploadedDate
        self.errors = errors
        self.warnings = warnings
        self.infos = infos
    }

    private enum CodingKeys: String, CodingKey {
        case id, appId, version, buildNumber, platform, state, createdDate, uploadedDate, errors, warnings, infos
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        appId = try container.decode(String.self, forKey: .appId)
        version = try container.decode(String.self, forKey: .version)
        buildNumber = try container.decode(String.self, forKey: .buildNumber)
        platform = try container.decode(BuildUploadPlatform.self, forKey: .platform)
        state = try container.decode(BuildUploadState.self, forKey: .state)
        createdDate = try container.decodeIfPresent(Date.self, forKey: .createdDate)
        uploadedDate = try container.decodeIfPresent(Date.self, forKey: .uploadedDate)
        errors = try container.decodeIfPresent([BuildUploadStateDetail].self, forKey: .errors) ?? []
        warnings = try container.decodeIfPresent([BuildUploadStateDetail].self, forKey: .warnings) ?? []
        infos = try container.decodeIfPresent([BuildUploadStateDetail].self, forKey: .infos) ?? []
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(appId, forKey: .appId)
        try container.encode(version, forKey: .version)
        try container.encode(buildNumber, forKey: .buildNumber)
        try container.encode(platform, forKey: .platform)
        try container.encode(state, forKey: .state)
        try container.encodeIfPresent(createdDate, forKey: .createdDate)
        try container.encodeIfPresent(uploadedDate, forKey: .uploadedDate)
        if !errors.isEmpty { try container.encode(errors, forKey: .errors) }
        if !warnings.isEmpty { try container.encode(warnings, forKey: .warnings) }
        if !infos.isEmpty { try container.encode(infos, forKey: .infos) }
    }
}

extension BuildUpload: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Version", "Build", "State"]
    }
    public var tableRow: [String] {
        [id, version, buildNumber, state.rawValue]
    }
}

extension BuildUpload: AffordanceProviding {
    public var affordances: [String: String] {
        var cmds: [String: String] = [
            "checkStatus": "asc builds uploads get --upload-id \(id)"
        ]
        if state.isComplete && !appId.isEmpty {
            cmds["listBuilds"] = "asc builds list --app-id \(appId)"
        }
        return cmds
    }
}

public enum BuildUploadPlatform: String, Sendable, Equatable, Codable {
    case iOS = "IOS"
    case macOS = "MAC_OS"
    case tvOS = "TV_OS"
    case visionOS = "VISION_OS"

    public init?(cliArgument: String) {
        switch cliArgument.lowercased() {
        case "ios": self = .iOS
        case "macos": self = .macOS
        case "tvos": self = .tvOS
        case "visionos": self = .visionOS
        default: return nil
        }
    }
}

public enum BuildUploadState: String, Sendable, Equatable, Codable {
    case awaitingUpload = "AWAITING_UPLOAD"
    case processing = "PROCESSING"
    case failed = "FAILED"
    case complete = "COMPLETE"

    public var isComplete: Bool { self == .complete }
    public var hasFailed: Bool { self == .failed }
    public var isPending: Bool { self == .awaitingUpload || self == .processing }
}
