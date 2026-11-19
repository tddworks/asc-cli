import Foundation
import Mockable
import Testing
@testable import ASCKit

@Suite
struct ComplianceAnswerTests {
    private let proof = ComplianceFile(name: "proof.pdf", data: Data([1]))
    private let report = ComplianceFile(name: "report.png", data: Data([2]))

    // MARK: - files

    @Test func `should type a file by its extension, ignoring case`() {
        #expect(ComplianceFile(name: "report.PDF", data: Data()).mimeType == "application/pdf")
        #expect(ComplianceFile(name: "proof.png", data: Data()).mimeType == "image/png")
        #expect(ComplianceFile(name: "proof.jpg", data: Data()).mimeType == "image/jpeg")
        #expect(ComplianceFile(name: "proof.jpeg", data: Data()).mimeType == "image/jpeg")
        #expect(ComplianceFile(name: "agreement.doc", data: Data()).mimeType == "application/msword")
        #expect(ComplianceFile(name: "agreement.docx", data: Data()).mimeType
            == "application/vnd.openxmlformats-officedocument.wordprocessingml.document")
        #expect(ComplianceFile(name: "notes.bin", data: Data()).mimeType == "application/octet-stream")
    }

    // MARK: - a Yes carries its kind's evidence (law 3)

    @Test func `should build a Security Assessment Yes from its proof and report`() throws {
        let answer = try ComplianceAnswer.offered(for: .securityAssessment, evidence: ComplianceEvidenceInput(proof: proof, report: report))

        #expect(answer == .offered(.securityAssessment(proof: proof, report: report)))
    }

    @Test func `should refuse a Security Assessment Yes without its report`() {
        #expect(throws: ComplianceError.evidenceMissing(kind: .securityAssessment, missing: ["the Security Assessment Report"])) {
            try ComplianceAnswer.offered(for: .securityAssessment, evidence: ComplianceEvidenceInput(proof: proof))
        }
    }

    @Test func `should build an AIGC Yes from an LLM filing that uses no third-party technology`() throws {
        let answer = try ComplianceAnswer.offered(for: .aiGeneratedContent, evidence: ComplianceEvidenceInput(
            filingType: .largeLanguageModel, filingName: "Example Model", filingNumber: "Example-0000"
        ))

        #expect(answer == .offered(.aiGeneratedContent(
            filing: .largeLanguageModel(name: "Example Model", filingNumber: "Example-0000"), thirdParty: .none
        )))
    }

    @Test func `should build an AIGC Yes whose third-party technology carries its authorization`() throws {
        let agreement = ComplianceFile(name: "agreement.pdf", data: Data([3]))

        let answer = try ComplianceAnswer.offered(for: .aiGeneratedContent, evidence: ComplianceEvidenceInput(
            filingType: .algorithm, filingName: "Recommender", filingNumber: "Algo-1", thirdPartyAuthorization: agreement
        ))

        #expect(answer == .offered(.aiGeneratedContent(
            filing: .algorithm(name: "Recommender", filingNumber: "Algo-1"), thirdParty: .used(authorization: agreement)
        )))
    }

    @Test func `should refuse an AIGC Yes without its filing details`() {
        #expect(throws: ComplianceError.evidenceMissing(kind: .aiGeneratedContent, missing: ["the filing type", "the filing number"])) {
            try ComplianceAnswer.offered(for: .aiGeneratedContent, evidence: ComplianceEvidenceInput(filingName: "Example Model"))
        }
    }

    @Test func `should refuse a Yes for a compliance asc doesn't know`() {
        #expect(throws: ComplianceError.notDeclarable(kind: .unrecognized(formName: "MEDICALDEV0001"), status: .missingInfo)) {
            try ComplianceAnswer.offered(for: .unrecognized(formName: "MEDICALDEV0001"), evidence: ComplianceEvidenceInput())
        }
    }

    @Test func `should say what a Yes still needs`() {
        #expect(ComplianceError.evidenceMissing(kind: .securityAssessment, missing: ["the Security Assessment Report"]).description
            == "A Yes to Security Assessment needs the Security Assessment Report.")
        #expect(ComplianceError.evidenceMissing(kind: .aiGeneratedContent, missing: ["the filing type", "the filing number"]).description
            == "A Yes to AI Generated or Synthetic Content needs the filing type and the filing number.")
    }

    // MARK: - the evidence must be the requirement's own

    @Test func `should refuse evidence made for another compliance, sending nothing`() async {
        let aigc = ComplianceRequirement(id: "req-2", appId: "1234567890", kind: .aiGeneratedContent, regions: ["CHN"], isRequired: true,
                                         status: .missingInfo, updatedAt: nil, requiredActions: [], declaration: nil)
        let repo = MockIrisComplianceRepository()

        await #expect(throws: ComplianceError.evidenceMismatch(kind: .aiGeneratedContent)) {
            try await aigc.declare(.offered(.securityAssessment(proof: proof, report: report)),
                                   session: IrisSession(cookies: "c"), repo: repo)
        }
        verify(repo).declare(session: .any, requirement: .any, answer: .any).called(0)
    }
}
