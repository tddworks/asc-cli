import Foundation
import Mockable
import Testing
@testable import ASCKit

@Suite
struct ComplianceRequirementTests {
    private let session = IrisSession(cookies: "myacinfo=a")

    private func requirement(
        _ kind: ComplianceKind = .securityAssessment,
        status: ComplianceStatus,
        declaration: ComplianceDeclaration? = nil,
        requiredActions: [ComplianceRequiredAction] = []
    ) -> ComplianceRequirement {
        ComplianceRequirement(
            id: "req-1", appId: "1234567890", kind: kind, regions: ["CHN"], isRequired: true,
            status: status, updatedAt: declaration == nil ? nil : "2026-11-17T00:00:00.000Z",
            requiredActions: requiredActions, declaration: declaration
        )
    }

    // MARK: - affordances (law 5)

    @Test func `should offer to declare a requirement nobody has answered`() {
        #expect(requirement(status: .missingInfo).affordances["declare"]
            == "asc iris app-compliance declare --answer <yes|no> --app-id 1234567890 --requirement-id req-1")
    }

    @Test func `should offer to change an active declaration and to resubmit a failed one`() {
        let answered = ComplianceDeclaration(id: "form-1", answer: .no)
        #expect(requirement(status: .active, declaration: answered).affordances["declare"] != nil)
        #expect(requirement(status: .verificationFailed, declaration: answered).affordances["declare"] != nil)
    }

    @Test func `should not offer to declare while Apple is verifying the answer`() {
        let yes = ComplianceDeclaration(id: "form-1", answer: .yes)
        #expect(requirement(status: .pendingVerification, declaration: yes).affordances["declare"] == nil)
    }

    @Test func `should not offer to declare a kind it doesn't know`() {
        #expect(requirement(.unrecognized(formName: "MEDICALDEV0001"), status: .missingInfo).affordances["declare"] == nil)
    }

    @Test func `should always point back to the app's compliance list`() {
        #expect(requirement(status: .active).affordances["listRequirements"]
            == "asc iris app-compliance list --app-id 1234567890")
    }

    @Test func `should link a declaration over REST under its app`() {
        #expect(requirement(status: .missingInfo).apiLinks["declare"]
            == APILink(href: "/api/v1/iris/apps/1234567890/compliance-requirements/req-1/declare", method: "POST"))
        #expect(requirement(status: .missingInfo).apiLinks["listRequirements"]
            == APILink(href: "/api/v1/iris/apps/1234567890/compliance-requirements", method: "GET"))
    }

    // MARK: - declare (law 5, refused by the model before anything is sent)

    @Test func `should send a No to Apple through the repository`() async throws {
        let declared = requirement(status: .active, declaration: ComplianceDeclaration(id: "form-1", answer: .no))
        let repo = MockIrisComplianceRepository()
        given(repo).declare(session: .any, requirement: .any, answer: .value(.notOffered)).willReturn(declared)

        #expect(try await requirement(status: .missingInfo).declare(.notOffered, session: session, repo: repo) == declared)
    }

    @Test func `should refuse to declare while Apple is verifying, sending nothing`() async {
        let repo = MockIrisComplianceRepository()

        await #expect(throws: ComplianceError.notDeclarable(kind: .securityAssessment, status: .pendingVerification)) {
            try await requirement(status: .pendingVerification, declaration: ComplianceDeclaration(id: "form-1", answer: .yes))
                .declare(.notOffered, session: session, repo: repo)
        }
        verify(repo).declare(session: .any, requirement: .any, answer: .any).called(0)
    }

    @Test func `should say why a requirement can't be declared`() {
        #expect(ComplianceError.notDeclarable(kind: .securityAssessment, status: .pendingVerification).description
            == "Security Assessment can't be changed while it is Pending Verification: Apple is checking the last answer.")
        #expect(ComplianceError.notDeclarable(kind: .unrecognized(formName: "MEDICALDEV0001"), status: .missingInfo).description
            == "MEDICALDEV0001 is a compliance asc doesn't know yet, so it can't declare it. Answer it on the App Compliance page.")
    }

    // MARK: - what it writes

    @Test func `should write a requirement the way the App Compliance page reads`() throws {
        let row = requirement(status: .pendingVerification, declaration: ComplianceDeclaration(id: "form-1", answer: .yes),
                              requiredActions: [.appBinarySubmission])
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        #expect(String(decoding: try encoder.encode(row), as: UTF8.self) == #"{"appId":"1234567890","declaration":{"answer":"YES","id":"form-1"},"id":"req-1","isRequired":true,"kind":"SECURITY_ASSESSMENT","name":"Security Assessment","regions":["CHN"],"requiredActions":["APP_BINARY_SUBMISSION"],"status":"PENDING_VERIFICATION","updatedAt":"2026-11-17T00:00:00.000Z"}"#)
    }

    @Test func `should leave out the declaration and date of a requirement nobody has answered`() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        #expect(String(decoding: try encoder.encode(requirement(status: .missingInfo)), as: UTF8.self) == #"{"appId":"1234567890","id":"req-1","isRequired":true,"kind":"SECURITY_ASSESSMENT","name":"Security Assessment","regions":["CHN"],"requiredActions":[],"status":"MISSING_INFO"}"#)
    }

    @Test func `should keep a required action it has not seen`() {
        #expect(ComplianceRequiredAction(wireValue: "APP_BINARY_SUBMISSION") == .appBinarySubmission)
        #expect(ComplianceRequiredAction(wireValue: "SIGN_AGREEMENT") == .unrecognized(wireValue: "SIGN_AGREEMENT"))
    }
}
