/// One row on an app's App Compliance page: a compliance that applies to the app in
/// a region, and the declaration that answers it. Apple's requirement id names the
/// compliance for the whole account, so a row is the id **and** its app (law 2).
public struct ComplianceRequirement: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    /// Parent: Apple's `entityId`, injected by the adapter.
    public let appId: String
    public let kind: ComplianceKind
    /// Where it applies, as Apple's `countries` codes (`CHN` = China mainland).
    public let regions: [String]
    public let isRequired: Bool
    public let status: ComplianceStatus
    /// LAST UPDATED, as Apple's ISO 8601 `lastUpdatedDate`; nil = never answered.
    public let updatedAt: String?
    public let requiredActions: [ComplianceRequiredAction]
    /// nil = never answered.
    public let declaration: ComplianceDeclaration?

    public init(
        id: String, appId: String, kind: ComplianceKind, regions: [String], isRequired: Bool,
        status: ComplianceStatus, updatedAt: String?, requiredActions: [ComplianceRequiredAction],
        declaration: ComplianceDeclaration?
    ) {
        self.id = id
        self.appId = appId
        self.kind = kind
        self.regions = regions
        self.isRequired = isRequired
        self.status = status
        self.updatedAt = updatedAt
        self.requiredActions = requiredActions
        self.declaration = declaration
    }

    /// A first answer (Missing Info), a change (Active) or a resubmission (Verification
    /// Failed) — never while Apple is verifying, and never a kind asc doesn't know (law 5).
    public var isDeclarable: Bool { kind.isRecognized && !status.isPendingVerification }

    public var isActive: Bool { status.isActive }
    public var needsAction: Bool { status.needsAction }

    /// Saves `answer` through `repo`, after checking this requirement may be declared.
    public func declare(_ answer: ComplianceAnswer, session: IrisSession, repo: any IrisComplianceRepository) async throws -> ComplianceRequirement {
        guard isDeclarable else { throw ComplianceError.notDeclarable(kind: kind, status: status) }
        return try await repo.declare(session: session, requirement: self, answer: answer)
    }

    private enum CodingKeys: String, CodingKey {
        case id, appId, kind, name, regions, isRequired, status, updatedAt, requiredActions, declaration
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try c.decode(String.self, forKey: .id),
            appId: try c.decode(String.self, forKey: .appId),
            kind: try c.decode(ComplianceKind.self, forKey: .kind),
            regions: try c.decode([String].self, forKey: .regions),
            isRequired: try c.decode(Bool.self, forKey: .isRequired),
            status: try c.decode(ComplianceStatus.self, forKey: .status),
            updatedAt: try c.decodeIfPresent(String.self, forKey: .updatedAt),
            requiredActions: try c.decode([ComplianceRequiredAction].self, forKey: .requiredActions),
            declaration: try c.decodeIfPresent(ComplianceDeclaration.self, forKey: .declaration)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(appId, forKey: .appId)
        try c.encode(kind, forKey: .kind)
        try c.encode(kind.displayName, forKey: .name)
        try c.encode(regions, forKey: .regions)
        try c.encode(isRequired, forKey: .isRequired)
        try c.encode(status, forKey: .status)
        try c.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try c.encode(requiredActions, forKey: .requiredActions)
        try c.encodeIfPresent(declaration, forKey: .declaration)
    }
}

extension ComplianceRequirement: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        var items = [
            Affordance(key: "listRequirements", command: "iris app-compliance", action: "list", params: ["app-id": appId]),
        ]
        if isDeclarable {
            items.append(Affordance(key: "declare", command: "iris app-compliance", action: "declare",
                                    params: ["app-id": appId, "requirement-id": id, "answer": "<yes|no>"]))
        }
        return items
    }
}

extension ComplianceRequirement: Presentable {
    public static var tableHeaders: [String] { ["Requirement ID", "Compliance", "Regions", "Status", "Answer", "Last Updated"] }
    public var tableRow: [String] {
        [id, kind.displayName, regions.joined(separator: ", "), status.displayName,
         declaration?.answer.rawValue ?? "-", updatedAt ?? "-"]
    }
}
