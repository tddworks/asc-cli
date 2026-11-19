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
    }

    struct Validation: Decodable {
        let required: Bool?
        let editable: Bool?
    }

    let presentation: Presentation
    let validation: Validation?

    var id: String { presentation.id }
    /// Apple marks a field `editable` only when it will take a change; a pending declaration has none.
    var isEditable: Bool { validation?.editable == true }
}

/// The draft Apple computes a form for (`…/metadata`).
struct ComplianceMetadataRequest: Encodable {
    struct Draft: Encodable {
        let fields: [ComplianceFieldValue]
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
    let fields: [ComplianceFieldValue]
}

struct ComplianceFormsResponse: Decodable {
    let data: [ComplianceFormResource]
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
