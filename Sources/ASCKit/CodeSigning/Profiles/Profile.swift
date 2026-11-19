import Foundation

public struct Profile: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let name: String
    public let profileType: ProfileType
    public let profileState: ProfileState
    /// Parent bundle ID — always present so agents can correlate with the associated bundle identifier.
    public let bundleIdId: String
    public let expirationDate: Date?
    public let uuid: String?
    public let profileContent: String?

    public init(
        id: String,
        name: String,
        profileType: ProfileType,
        profileState: ProfileState = .active,
        bundleIdId: String,
        expirationDate: Date? = nil,
        uuid: String? = nil,
        profileContent: String? = nil
    ) {
        self.id = id
        self.name = name
        self.profileType = profileType
        self.profileState = profileState
        self.bundleIdId = bundleIdId
        self.expirationDate = expirationDate
        self.uuid = uuid
        self.profileContent = profileContent
    }

    public var isActive: Bool { profileState == .active }
}

extension Profile: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Name", "Type", "State"]
    }
    public var tableRow: [String] {
        [id, name, profileType.rawValue, profileState.rawValue]
    }
}

extension Profile: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "delete": "asc profiles delete --profile-id \(id)",
            "listProfiles": "asc profiles list --bundle-id-id \(bundleIdId)",
        ]
    }
}

public enum ProfileType: String, Sendable, Equatable, Codable, CaseIterable {
    case iosAppDevelopment = "IOS_APP_DEVELOPMENT"
    case iosAppStore = "IOS_APP_STORE"
    case iosAppAdhoc = "IOS_APP_ADHOC"
    case iosAppInhouse = "IOS_APP_INHOUSE"
    case macAppDevelopment = "MAC_APP_DEVELOPMENT"
    case macAppStore = "MAC_APP_STORE"
    case macAppDirect = "MAC_APP_DIRECT"
    case tvosAppDevelopment = "TVOS_APP_DEVELOPMENT"
    case tvosAppStore = "TVOS_APP_STORE"
    case tvosAppAdhoc = "TVOS_APP_ADHOC"
    case tvosAppInhouse = "TVOS_APP_INHOUSE"
    case macCatalystAppDevelopment = "MAC_CATALYST_APP_DEVELOPMENT"
    case macCatalystAppStore = "MAC_CATALYST_APP_STORE"
    case macCatalystAppDirect = "MAC_CATALYST_APP_DIRECT"
}

public enum ProfileState: String, Sendable, Equatable, Codable {
    case active = "ACTIVE"
    case invalid = "INVALID"
}
