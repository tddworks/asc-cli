import Foundation

public struct DiagnosticLogEntry: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let signatureId: String
    public let bundleId: String?
    public let appVersion: String?
    public let buildVersion: String?
    public let osVersion: String?
    public let deviceType: String?
    public let event: String?
    public let callStackSummary: String?

    public init(
        id: String,
        signatureId: String,
        bundleId: String? = nil,
        appVersion: String? = nil,
        buildVersion: String? = nil,
        osVersion: String? = nil,
        deviceType: String? = nil,
        event: String? = nil,
        callStackSummary: String? = nil
    ) {
        self.id = id
        self.signatureId = signatureId
        self.bundleId = bundleId
        self.appVersion = appVersion
        self.buildVersion = buildVersion
        self.osVersion = osVersion
        self.deviceType = deviceType
        self.event = event
        self.callStackSummary = callStackSummary
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.signatureId = try container.decode(String.self, forKey: .signatureId)
        self.bundleId = try container.decodeIfPresent(String.self, forKey: .bundleId)
        self.appVersion = try container.decodeIfPresent(String.self, forKey: .appVersion)
        self.buildVersion = try container.decodeIfPresent(String.self, forKey: .buildVersion)
        self.osVersion = try container.decodeIfPresent(String.self, forKey: .osVersion)
        self.deviceType = try container.decodeIfPresent(String.self, forKey: .deviceType)
        self.event = try container.decodeIfPresent(String.self, forKey: .event)
        self.callStackSummary = try container.decodeIfPresent(String.self, forKey: .callStackSummary)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(signatureId, forKey: .signatureId)
        try container.encodeIfPresent(bundleId, forKey: .bundleId)
        try container.encodeIfPresent(appVersion, forKey: .appVersion)
        try container.encodeIfPresent(buildVersion, forKey: .buildVersion)
        try container.encodeIfPresent(osVersion, forKey: .osVersion)
        try container.encodeIfPresent(deviceType, forKey: .deviceType)
        try container.encodeIfPresent(event, forKey: .event)
        try container.encodeIfPresent(callStackSummary, forKey: .callStackSummary)
    }

    private enum CodingKeys: String, CodingKey {
        case id, signatureId, bundleId, appVersion, buildVersion, osVersion, deviceType, event, callStackSummary
    }
}

extension DiagnosticLogEntry: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        [
            Affordance(key: "listLogs", command: "diagnostic-logs", action: "list", params: ["signature-id": signatureId]),
        ]
    }
}

extension DiagnosticLogEntry: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Bundle ID", "Version", "OS", "Device", "Event"]
    }

    public var tableRow: [String] {
        [id, bundleId ?? "-", appVersion ?? "-", osVersion ?? "-", deviceType ?? "-", event ?? "-"]
    }
}
