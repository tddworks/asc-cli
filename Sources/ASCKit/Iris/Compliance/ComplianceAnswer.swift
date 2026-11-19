import Foundation

/// The developer's answer to a requirement's question ("Does your app offer AIGC services
/// in China mainland?"). A No carries nothing; a Yes carries its kind's evidence, in a shape
/// that can't hold a combination the form can't (law 3).
public enum ComplianceAnswer: Sendable, Equatable {
    /// The app doesn't offer the regulated feature in the region, or it's disabled or geoblocked there.
    case notOffered
    case offered(ComplianceEvidence)

    /// The question's option, as Apple's form names it.
    var wireValue: String {
        switch self {
        case .notOffered: "NO"
        case .offered: "YES"
        }
    }

    /// Whether this answer is one `kind` can take: a No always; a Yes only with its own evidence.
    func fits(_ kind: ComplianceKind) -> Bool {
        switch (self, kind) {
        case (.notOffered, _): true
        case (.offered(.securityAssessment), .securityAssessment): true
        case (.offered(.aiGeneratedContent), .aiGeneratedContent): true
        default: false
        }
    }

    /// A Yes to `kind`, from evidence given piece by piece (flags, a REST body).
    /// Refuses, naming what's missing, when the kind's evidence isn't all there.
    public static func offered(for kind: ComplianceKind, evidence: ComplianceEvidenceInput) throws -> ComplianceAnswer {
        switch kind {
        case .securityAssessment:
            var missing: [String] = []
            if evidence.proof == nil { missing.append("the Proof of a Completed Security Assessment") }
            if evidence.report == nil { missing.append("the Security Assessment Report") }
            guard let proof = evidence.proof, let report = evidence.report else {
                throw ComplianceError.evidenceMissing(kind: kind, missing: missing)
            }
            return .offered(.securityAssessment(proof: proof, report: report))
        case .aiGeneratedContent:
            var missing: [String] = []
            if evidence.filingType == nil { missing.append("the filing type") }
            if evidence.filingName == nil { missing.append("the filing name") }
            if evidence.filingNumber == nil { missing.append("the filing number") }
            guard let type = evidence.filingType, let name = evidence.filingName, let number = evidence.filingNumber else {
                throw ComplianceError.evidenceMissing(kind: kind, missing: missing)
            }
            let filing: AIGCFiling = switch type {
            case .algorithm: .algorithm(name: name, filingNumber: number)
            case .largeLanguageModel: .largeLanguageModel(name: name, filingNumber: number)
            }
            return .offered(.aiGeneratedContent(
                filing: filing, thirdParty: evidence.thirdPartyAuthorization.map { .used(authorization: $0) } ?? .none
            ))
        case .unrecognized:
            throw ComplianceError.notDeclarable(kind: kind, status: .missingInfo)
        }
    }
}

/// What a Yes must carry, per kind.
public enum ComplianceEvidence: Sendable, Equatable {
    /// The proof of a completed security assessment, and the assessment report.
    case securityAssessment(proof: ComplianceFile, report: ComplianceFile)
    /// The AIGC filing, and whether third-party technology powers the feature.
    case aiGeneratedContent(filing: AIGCFiling, thirdParty: ThirdPartyTechnology)
}

/// The filing an AIGC Yes gives: an algorithm or a large language model, by name and filing number.
public enum AIGCFiling: Sendable, Equatable {
    case algorithm(name: String, filingNumber: String)
    case largeLanguageModel(name: String, filingNumber: String)

    public enum FilingType: String, Sendable, Equatable, CaseIterable {
        case algorithm
        case largeLanguageModel = "llm"
    }
}

/// Whether an app's AI features are powered by third-party technology; if so, the
/// authorization or usage agreement for it.
public enum ThirdPartyTechnology: Sendable, Equatable {
    case none
    case used(authorization: ComplianceFile)
}

/// A local document sent as evidence. Apple stores it on save; its type comes from its extension.
public struct ComplianceFile: Sendable, Equatable {
    public let name: String
    public let data: Data

    public init(name: String, data: Data) {
        self.name = name
        self.data = data
    }

    /// The extension with its dot, lowercased (`.pdf`), as Apple's `allowedFileTypes` spell it.
    public var fileExtension: String {
        let ext = (name as NSString).pathExtension.lowercased()
        return ext.isEmpty ? "" : ".\(ext)"
    }

    public var mimeType: String {
        switch fileExtension {
        case ".pdf": "application/pdf"
        case ".png": "image/png"
        case ".jpg", ".jpeg": "image/jpeg"
        case ".doc": "application/msword"
        case ".docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        default: "application/octet-stream"
        }
    }
}

/// Evidence as it arrives, piece by piece, before it's known to be complete for a kind.
public struct ComplianceEvidenceInput: Sendable, Equatable {
    public var proof: ComplianceFile?
    public var report: ComplianceFile?
    public var filingType: AIGCFiling.FilingType?
    public var filingName: String?
    public var filingNumber: String?
    public var thirdPartyAuthorization: ComplianceFile?

    public init(
        proof: ComplianceFile? = nil, report: ComplianceFile? = nil,
        filingType: AIGCFiling.FilingType? = nil, filingName: String? = nil, filingNumber: String? = nil,
        thirdPartyAuthorization: ComplianceFile? = nil
    ) {
        self.proof = proof
        self.report = report
        self.filingType = filingType
        self.filingName = filingName
        self.filingNumber = filingNumber
        self.thirdPartyAuthorization = thirdPartyAuthorization
    }
}
