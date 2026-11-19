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

    /// The page's own call: every requirement, answered or not, with its status, date and
    /// the declaration that answers it. The declarations themselves aren't read.
    public func listRequirements(session: IrisSession, appId: String) async throws -> [ComplianceRequirement] {
        let team = try await teamId(for: session)
        let (data, _) = try await api.complianceGet(
            path: "accounts/\(team)/requirements", queryItems: [URLQueryItem(name: "entity_id", value: appId)], cookies: session.cookies
        )
        return try JSONDecoder().decode(ComplianceRequirementsResponse.self, from: data).data.map { requirement in
            ComplianceRequirement(
                id: requirement.id,
                appId: appId,
                kind: ComplianceKind(formName: requirement.formName),
                regions: requirement.countries ?? [],
                isRequired: requirement.isRequired ?? false,
                status: ComplianceStatus(wireValue: requirement.status),
                updatedAt: requirement.lastUpdatedDate,
                requiredActions: (requirement.requiredActions ?? []).map(ComplianceRequiredAction.init(wireValue:)),
                declarationId: requirement.formId
            )
        }
    }

    /// Saves `answer` the way the App Compliance page does: post the draft to Apple's form,
    /// fill every field it newly asks for from the answer, and again until it asks for nothing
    /// new; then save exactly the fields the form asks for (laws 8, 10) — a `POST` for a first
    /// answer, a `PUT` on the declaration for a change.
    public func declare(session: IrisSession, requirement: ComplianceRequirement, answer: ComplianceAnswer) async throws -> ComplianceRequirement {
        let team = try await teamId(for: session)
        let entity = "accounts/\(team)/entities/\(requirement.appId)"

        var draft: [ComplianceDraftField] = []
        var form = try await metadata(for: draft, requirement: requirement, team: team, session: session)
        var settled = false
        for _ in 0..<Self.maxPicks {
            // Apple decides what may change: a field it won't take a change to stops everything (law 5a).
            guard !form.constraints.isEmpty, form.constraints.values.allSatisfy(\.isEditable) else {
                throw ComplianceError.readOnly(kind: requirement.kind)
            }
            let asked = form.constraints.values
                .filter { field in !draft.contains { $0.id == field.id } }
                .sorted { $0.id < $1.id }
            if asked.isEmpty { settled = true; break }
            for field in asked {
                draft.append(try Self.fill(field, from: answer, kind: requirement.kind))
            }
            form = try await metadata(for: draft, requirement: requirement, team: team, session: session)
        }
        guard settled else { throw ComplianceError.formNotUnderstood(kind: requirement.kind, field: "a form that never settles") }
        let fields = draft.filter { form.constraints[$0.id] != nil }

        let body = try Self.encoder.encode(ComplianceSaveRequest(
            accountId: team, entityId: requirement.appId, requirementId: requirement.id,
            formId: requirement.declarationId, fields: fields
        ))
        do {
            if let formId = requirement.declarationId {
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

    /// The AIGC tree is three picks deep; more than this means a form asc doesn't understand.
    private static let maxPicks = 8

    /// One field Apple's form asks for, filled from the answer. A field is known by the key in
    /// its label (law 8); a file must be a type the field accepts (law 9).
    private static func fill(_ field: ComplianceConstraint, from answer: ComplianceAnswer, kind: ComplianceKind) throws -> ComplianceDraftField {
        guard let key = field.fieldKey, let value = answer.value(forFieldKey: key) else {
            throw ComplianceError.formNotUnderstood(kind: kind, field: field.fieldKey ?? field.id)
        }
        switch value {
        case .text(let text):
            return .text(field.id, text)
        case .file(let file):
            let allowed = field.allowedFileTypes
            guard allowed.isEmpty || allowed.contains(file.fileExtension) else {
                throw ComplianceError.fileTypeNotAllowed(fileName: file.name, allowed: allowed)
            }
            return .file(field.id, file)
        }
    }

    private func metadata(
        for fields: [ComplianceDraftField], requirement: ComplianceRequirement, team: String, session: IrisSession
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
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return encoder
    }()

    private func teamId(for session: IrisSession) async throws -> String {
        guard let team = try await accounts.fetchSession(cookies: session.cookies).teamId, !team.isEmpty else {
            throw ComplianceError.teamUnknown
        }
        return team
    }
}

/// What an answer gives each field of Apple's forms, known by the field key in its label.
/// The keys are the captured ones (docs/features/app-compliance/design.md): a short label
/// slug with a suffix, matched by the slug so a new suffix still reads.
extension ComplianceAnswer {
    enum FieldValue {
        case text(String)
        case file(ComplianceFile)
    }

    func value(forFieldKey key: String) -> FieldValue? {
        // Every form opens with its Yes/No question ("Does your app …?").
        if key.hasPrefix("doesyourap") { return .text(wireValue) }
        guard case .offered(let evidence) = self else { return nil }
        switch evidence {
        case .securityAssessment(let proof, let report):
            if key.hasPrefix("proofofaco") { return .file(proof) }
            if key.hasPrefix("securityas") { return .file(report) }
        case .aiGeneratedContent(let filing, let thirdParty):
            switch (filing, key) {
            case (_, let key) where key.hasPrefix("whichfilin"):
                if case .algorithm = filing { return .text("ALGOR") }
                return .text("LARGE")
            case (.algorithm(let name, _), let key) where key.hasPrefix("algorithmn"): return .text(name)
            case (.algorithm(_, let number), let key) where key.hasPrefix("algorithmf"): return .text(number)
            case (.largeLanguageModel(let name, _), let key) where key.hasPrefix("llmname"): return .text(name)
            case (.largeLanguageModel(_, let number), let key) where key.hasPrefix("llmfilingn"): return .text(number)
            default: break
            }
            if key.hasPrefix("areyourapp") {
                if case .used = thirdParty { return .text("YES") }
                return .text("NO")
            }
            if key.hasPrefix("authorizat"), case .used(let authorization) = thirdParty { return .file(authorization) }
        }
        return nil
    }
}
