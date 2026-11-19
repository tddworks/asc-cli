import Foundation
import Mockable

// MARK: - Request / Result types

public struct ArchiveRequest: Sendable, Equatable {
    public let scheme: String
    public let workspace: String?
    public let project: String?
    public let platform: BuildUploadPlatform
    public let configuration: String
    public let archivePath: String

    public init(
        scheme: String,
        workspace: String? = nil,
        project: String? = nil,
        platform: BuildUploadPlatform = .iOS,
        configuration: String = "Release",
        archivePath: String
    ) {
        self.scheme = scheme
        self.workspace = workspace
        self.project = project
        self.platform = platform
        self.configuration = configuration
        self.archivePath = archivePath
    }
}

public struct ArchiveResult: Sendable, Equatable, Codable {
    public let archivePath: String
    public let scheme: String
    public let platform: BuildUploadPlatform

    public init(archivePath: String, scheme: String, platform: BuildUploadPlatform) {
        self.archivePath = archivePath
        self.scheme = scheme
        self.platform = platform
    }
}

extension ArchiveResult: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "exportArchive": "asc builds export --archive-path \(archivePath)"
        ]
    }
}

public enum SigningStyle: String, Sendable, Equatable, Codable {
    case automatic = "automatic"
    case manual = "manual"
}

public struct ExportRequest: Sendable, Equatable {
    public let archivePath: String
    public let exportPath: String
    public let method: ExportMethod
    public let signingStyle: SigningStyle
    public let teamId: String?

    public init(
        archivePath: String,
        exportPath: String,
        method: ExportMethod = .appStoreConnect,
        signingStyle: SigningStyle = .automatic,
        teamId: String? = nil
    ) {
        self.archivePath = archivePath
        self.exportPath = exportPath
        self.method = method
        self.signingStyle = signingStyle
        self.teamId = teamId
    }
}

public struct ExportResult: Sendable, Equatable, Codable {
    public let ipaPath: String
    public let exportPath: String

    public init(ipaPath: String, exportPath: String) {
        self.ipaPath = ipaPath
        self.exportPath = exportPath
    }
}

extension ExportResult: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "upload": "asc builds upload --file \(ipaPath)"
        ]
    }
}

public enum ExportMethod: String, Sendable, Equatable, Codable {
    case appStoreConnect = "app-store-connect"
    case adHoc = "ad-hoc"
    case development = "development"
    case enterprise = "enterprise"

    public init?(cliArgument: String) {
        self.init(rawValue: cliArgument)
    }
}

// MARK: - Runner protocol

@Mockable
public protocol XcodeBuildRunner: Sendable {
    func archive(request: ArchiveRequest) async throws -> ArchiveResult
    func exportArchive(request: ExportRequest) async throws -> ExportResult
}
