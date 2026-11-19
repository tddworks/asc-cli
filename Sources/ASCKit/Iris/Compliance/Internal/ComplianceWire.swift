import Foundation

// The App Compliance service's JSON (`ppm/compliancerequirements/v1`), as captured in
// docs/features/app-compliance/design.md. Only what the domain reads is decoded.

struct ComplianceRequirementsResponse: Decodable {
    let data: [ComplianceRequirementResource]
}

struct ComplianceRequirementResource: Decodable {
    let id: String
    let formName: String
    let status: String
    let isRequired: Bool?
    let countries: [String]?
    let formId: String?
    let lastUpdatedDate: String?
    let requiredActions: [String]?
}

/// What a draft asks for: one constraint per field the current answers open.
struct ComplianceFormMetadata: Decodable {
    let constraints: [String: ComplianceConstraint]

    /// The Yes/No question a form opens with: the field an empty draft is asked for.
    var question: ComplianceConstraint? {
        constraints.values.first { $0.presentation.inputType == "RADIO" }
    }
}

struct ComplianceConstraint: Decodable {
    struct Presentation: Decodable {
        let id: String
        let inputType: String
        let label: String?
    }

    struct Validation: Decodable {
        let required: Bool?
        let editable: Bool?
        let allowedFileTypes: [String]?
    }

    let presentation: Presentation
    let validation: Validation?

    var id: String { presentation.id }
    /// Apple marks a field `editable` only when it will take a change; a pending declaration has none.
    var isEditable: Bool { validation?.editable == true }
    var isRequired: Bool { validation?.required == true }
    var allowedFileTypes: [String] { validation?.allowedFileTypes ?? [] }
    /// The field key inside its label's loc key (`…field.proofofacocb097.label` → `proofofacocb097`):
    /// how a field is known, since its id is Apple's to choose (law 8).
    var fieldKey: String? {
        guard let parts = presentation.label?.split(separator: "."), let at = parts.firstIndex(of: "field"),
              parts.index(after: at) < parts.endIndex else { return nil }
        return String(parts[parts.index(after: at)])
    }
}

/// One field of a draft: a `RADIO` or `TEXT` as `sValue`, a `FILE` as its base64 bytes in `fileContent`.
struct ComplianceDraftField: Encodable, Equatable {
    struct FileContent: Encodable, Equatable {
        let fileData: String
        let fileName: String
        let fileType: String
    }

    let id: String
    let sValue: String?
    let fileContent: FileContent?

    static func text(_ id: String, _ value: String) -> ComplianceDraftField {
        ComplianceDraftField(id: id, sValue: value, fileContent: nil)
    }

    static func file(_ id: String, _ file: ComplianceFile) -> ComplianceDraftField {
        ComplianceDraftField(id: id, sValue: nil, fileContent: FileContent(
            fileData: file.data.base64EncodedString(), fileName: file.name, fileType: file.mimeType
        ))
    }
}

/// The draft Apple computes a form for (`…/metadata`).
struct ComplianceMetadataRequest: Encodable {
    struct Draft: Encodable {
        let fields: [ComplianceDraftField]
    }

    let accountId: String
    let entityId: String
    let requirementId: String
    let form: Draft
}

/// A declaration being saved: a first answer (`POST …/forms`) or a change (`PUT …/forms/{formId}`).
struct ComplianceSaveRequest: Encodable {
    let accountId: String
    let entityId: String
    let requirementId: String
    let formId: String?
    let fields: [ComplianceDraftField]
}

struct ComplianceFormsResponse: Decodable {
    let data: [ComplianceFormResource]

    /// An app with no declarations yet is answered `{}`, with no `data` (seen live).
    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        data = try c.decodeIfPresent([ComplianceFormResource].self, forKey: .data) ?? []
    }

    private enum CodingKeys: String, CodingKey { case data }
}

struct ComplianceFormResponse: Decodable {
    let data: ComplianceFormResource
}

/// A declaration, which Apple calls a form.
struct ComplianceFormResource: Decodable {
    let id: String
    let requirementId: String
    let formName: String
    let fields: [ComplianceFieldValue]
    let status: String?
}

/// One answered field. A `RADIO` or `TEXT` holds `sValue`; a `FILE` holds `fileContent`.
struct ComplianceFieldValue: Codable, Equatable {
    let id: String
    let sValue: String?

    init(id: String, sValue: String) {
        self.id = id
        self.sValue = sValue
    }
}

extension ComplianceFormResource {
    /// The answer to the form's first question, the Yes/No every form opens with.
    /// Only a Yes opens further fields, so a form with more than that one is a Yes.
    var answer: ComplianceDeclaration.Answer {
        switch fields.first?.sValue {
        case "YES": .yes
        case "NO": .no
        default: fields.count > 1 ? .yes : .no
        }
    }
}
