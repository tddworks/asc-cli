import Foundation

public struct Certificate: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let name: String
    public let certificateType: CertificateType
    public let displayName: String?
    public let serialNumber: String?
    public let platform: BundleIDPlatform?
    public let expirationDate: Date?
    public let certificateContent: String?

    public init(
        id: String,
        name: String,
        certificateType: CertificateType,
        displayName: String? = nil,
        serialNumber: String? = nil,
        platform: BundleIDPlatform? = nil,
        expirationDate: Date? = nil,
        certificateContent: String? = nil
    ) {
        self.id = id
        self.name = name
        self.certificateType = certificateType
        self.displayName = displayName
        self.serialNumber = serialNumber
        self.platform = platform
        self.expirationDate = expirationDate
        self.certificateContent = certificateContent
    }

    public var isExpired: Bool {
        guard let expirationDate else { return false }
        return expirationDate < Date()
    }
}

extension Certificate: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Name", "Type", "Expired"]
    }
    public var tableRow: [String] {
        [id, name, certificateType.rawValue, isExpired ? "Yes" : "No"]
    }
}

extension Certificate: AffordanceProviding {
    public var affordances: [String: String] {
        ["revoke": "asc certificates revoke --certificate-id \(id)"]
    }
}

public enum CertificateType: String, Sendable, Equatable, Codable, CaseIterable {
    case development = "DEVELOPMENT"
    case distribution = "DISTRIBUTION"
    case iosDevelopment = "IOS_DEVELOPMENT"
    case iosDistribution = "IOS_DISTRIBUTION"
    case macAppDevelopment = "MAC_APP_DEVELOPMENT"
    case macAppDistribution = "MAC_APP_DISTRIBUTION"
    case macInstallerDistribution = "MAC_INSTALLER_DISTRIBUTION"
    case developerIDApplication = "DEVELOPER_ID_APPLICATION"
    case developerIDKext = "DEVELOPER_ID_KEXT"
}
