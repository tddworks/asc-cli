import Foundation

/// `IrisComplianceRepository` over the App Compliance service. Every call is scoped by
/// the team's `publicProviderId`, which olympus gives for the session (law 6).
public struct IrisSDKComplianceRepository: IrisComplianceRepository {
    private let api: any IrisAPI
    private let accounts: any AppStoreConnectAccounts

    public init() {
        self.init(api: IrisClient(), accounts: OlympusClient())
    }

    init(api: any IrisAPI, accounts: any AppStoreConnectAccounts) {
        self.api = api
        self.accounts = accounts
    }

    public func listRequirements(session: IrisSession, appId: String) async throws -> [ComplianceRequirement] {
        let team = try await teamId(for: session)
        let (requirementsData, _) = try await api.complianceGet(
            path: "accounts/\(team)/requirements", queryItems: [URLQueryItem(name: "entity_id", value: appId)], cookies: session.cookies
        )
        let (formsData, _) = try await api.complianceGet(
            path: "accounts/\(team)/entities/\(appId)/forms", queryItems: [], cookies: session.cookies
        )
        let requirements = try JSONDecoder().decode(ComplianceRequirementsResponse.self, from: requirementsData).data
        let forms = try JSONDecoder().decode(ComplianceFormsResponse.self, from: formsData).data
        return Self.rows(requirements: requirements, forms: forms, appId: appId)
    }

    /// Saves `answer` the way the App Compliance page does: ask Apple for the form, pick the
    /// answer and ask again, then save exactly the fields the form asks for (laws 8, 10) —
    /// a `POST` for a first answer, a `PUT` on the declaration for a change.
    public func declare(session: IrisSession, requirement: ComplianceRequirement, answer: ComplianceAnswer) async throws -> ComplianceRequirement {
        let team = try await teamId(for: session)
        let entity = "accounts/\(team)/entities/\(requirement.appId)"

        // The question's id comes from Apple's form, never from asc (law 8).
        let empty = try await metadata(for: [], requirement: requirement, team: team, session: session)
        guard let question = empty.question, question.isEditable else {
            throw ComplianceError.readOnly(kind: requirement.kind)
        }
        let draft = [ComplianceFieldValue(id: question.id, sValue: answer.wireValue)]
        let picked = try await metadata(for: draft, requirement: requirement, team: team, session: session)
        let fields = draft.filter { picked.constraints[$0.id] != nil }

        let body = try Self.encoder.encode(ComplianceSaveRequest(
            accountId: team, entityId: requirement.appId, requirementId: requirement.id,
            formId: requirement.declaration?.id, fields: fields
        ))
        do {
            if let formId = requirement.declaration?.id {
                _ = try await api.compliancePut(path: "\(entity)/forms/\(formId)", body: body, cookies: session.cookies)
            } else {
                _ = try await api.compliancePost(path: "\(entity)/forms", body: body, cookies: session.cookies)
            }
        } catch IrisAPIError.httpError(statusCode: 403, _) {
            throw ComplianceError.roleCannotEdit(appId: requirement.appId)
        }

        let rows = try await listRequirements(session: session, appId: requirement.appId)
        return rows.first { $0.id == requirement.id } ?? requirement
    }

    private func metadata(
        for fields: [ComplianceFieldValue], requirement: ComplianceRequirement, team: String, session: IrisSession
    ) async throws -> ComplianceFormMetadata {
        let body = try Self.encoder.encode(ComplianceMetadataRequest(
            accountId: team, entityId: requirement.appId, requirementId: requirement.id, form: .init(fields: fields)
        ))
        let (data, _) = try await api.compliancePost(
            path: "accounts/\(team)/entities/\(requirement.appId)/requirements/\(requirement.id)/metadata",
            body: body, cookies: session.cookies
        )
        return try JSONDecoder().decode(ComplianceFormMetadata.self, from: data)
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    /// Every requirement is a row, answered or not, with the form whose `requirementId` is
    /// its id (law 7). A form no requirement lists is still a row, but one that can't be
    /// declared: there is no requirement to save it against (law 4).
    static func rows(requirements: [ComplianceRequirementResource], forms: [ComplianceFormResource], appId: String) -> [ComplianceRequirement] {
        let formsByRequirement = Dictionary(forms.map { ($0.requirementId, $0) }, uniquingKeysWith: { first, _ in first })
        let listed = requirements.map { requirement in
            ComplianceRequirement(
                id: requirement.id,
                appId: appId,
                kind: ComplianceKind(formName: requirement.formName),
                regions: requirement.countries ?? [],
                isRequired: requirement.isRequired ?? false,
                status: ComplianceStatus(wireValue: requirement.status),
                updatedAt: requirement.lastUpdatedDate,
                requiredActions: (requirement.requiredActions ?? []).map(ComplianceRequiredAction.init(wireValue:)),
                declaration: formsByRequirement[requirement.id].map { ComplianceDeclaration(id: $0.id, answer: $0.answer) }
            )
        }
        let listedIds = Set(requirements.map(\.id))
        let orphans = forms.filter { !listedIds.contains($0.requirementId) }.map { form in
            ComplianceRequirement(
                id: form.requirementId,
                appId: appId,
                kind: .unrecognized(formName: form.formName),
                regions: [],
                isRequired: false,
                status: form.status.map(ComplianceStatus.init(wireValue:)) ?? .unrecognized(wireValue: ""),
                updatedAt: nil,
                requiredActions: [],
                declaration: ComplianceDeclaration(id: form.id, answer: form.answer)
            )
        }
        return listed + orphans
    }

    private func teamId(for session: IrisSession) async throws -> String {
        guard let team = try await accounts.fetchSession(cookies: session.cookies).teamId, !team.isEmpty else {
            throw ComplianceError.teamUnknown
        }
        return team
    }
}
