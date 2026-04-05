import Foundation

public struct Device: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let name: String
    public let udid: String
    public let deviceClass: DeviceClass
    public let platform: BundleIDPlatform
    public let status: DeviceStatus
    public let model: String?
    public let addedDate: Date?

    public init(
        id: String,
        name: String,
        udid: String,
        deviceClass: DeviceClass,
        platform: BundleIDPlatform,
        status: DeviceStatus = .enabled,
        model: String? = nil,
        addedDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.udid = udid
        self.deviceClass = deviceClass
        self.platform = platform
        self.status = status
        self.model = model
        self.addedDate = addedDate
    }

    public var isEnabled: Bool { status == .enabled }
}

extension Device: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Name", "UDID", "Class", "Status"]
    }
    public var tableRow: [String] {
        [id, name, udid, deviceClass.rawValue, status.rawValue]
    }
}

extension Device: AffordanceProviding {
    public var affordances: [String: String] {
        ["listDevices": "asc devices list"]
    }
}

public enum DeviceClass: String, Sendable, Equatable, Codable, CaseIterable {
    case appleWatch = "APPLE_WATCH"
    case iPad = "IPAD"
    case iPhone = "IPHONE"
    case iPod = "IPOD"
    case appleTV = "APPLE_TV"
    case mac = "MAC"
    case appleVisionPro = "APPLE_VISION_PRO"
}

public enum DeviceStatus: String, Sendable, Equatable, Codable {
    case enabled = "ENABLED"
    case disabled = "DISABLED"
}
