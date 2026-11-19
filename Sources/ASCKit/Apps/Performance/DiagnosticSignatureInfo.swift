import Foundation

public enum DiagnosticType: String, Sendable, Equatable, Codable, CaseIterable {
    case diskWrites = "DISK_WRITES"
    case hangs = "HANGS"
    case launches = "LAUNCHES"
}

public struct DiagnosticSignatureInfo: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let buildId: String
    public let diagnosticType: DiagnosticType
    public let signature: String
    public let weight: Double
    public let insightDirection: String?

    public init(
        id: String,
        buildId: String,
        diagnosticType: DiagnosticType,
        signature: String,
        weight: Double,
        insightDirection: String? = nil
    ) {
        self.id = id
        self.buildId = buildId
        self.diagnosticType = diagnosticType
        self.signature = signature
        self.weight = weight
        self.insightDirection = insightDirection
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.buildId = try container.decode(String.self, forKey: .buildId)
        self.diagnosticType = try container.decode(DiagnosticType.self, forKey: .diagnosticType)
        self.signature = try container.decode(String.self, forKey: .signature)
        self.weight = try container.decode(Double.self, forKey: .weight)
        self.insightDirection = try container.decodeIfPresent(String.self, forKey: .insightDirection)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(buildId, forKey: .buildId)
        try container.encode(diagnosticType, forKey: .diagnosticType)
        try container.encode(signature, forKey: .signature)
        try container.encode(weight, forKey: .weight)
        try container.encodeIfPresent(insightDirection, forKey: .insightDirection)
    }

    private enum CodingKeys: String, CodingKey {
        case id, buildId, diagnosticType, signature, weight, insightDirection
    }
}

extension DiagnosticSignatureInfo: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        [
            Affordance(key: "listLogs", command: "diagnostic-logs", action: "list", params: ["signature-id": id]),
            Affordance(key: "listSignatures", command: "diagnostics", action: "list", params: ["build-id": buildId]),
        ]
    }
}

extension DiagnosticSignatureInfo: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Type", "Signature", "Weight", "Trend"]
    }

    public var tableRow: [String] {
        [id, diagnosticType.rawValue, signature, String(weight), insightDirection ?? "-"]
    }
}
