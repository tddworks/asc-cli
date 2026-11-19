import Foundation
import Testing
@testable import ASCKit

@Suite
struct ComplianceKindTests {
    @Test func `should be the Security Assessment when Apple names the form SECURITYASF395E`() {
        #expect(ComplianceKind(formName: "SECURITYASF395E") == .securityAssessment)
    }

    @Test func `should be AI generated content when Apple names the form AIGENERATEFD1DE`() {
        #expect(ComplianceKind(formName: "AIGENERATEFD1DE") == .aiGeneratedContent)
    }

    @Test func `should keep a form it doesn't know, by Apple's name for it`() {
        #expect(ComplianceKind(formName: "MEDICALDEV0001") == .unrecognized(formName: "MEDICALDEV0001"))
        #expect(ComplianceKind(formName: "MEDICALDEV0001").isRecognized == false)
    }

    @Test func `should be named as the App Compliance page names it`() {
        #expect(ComplianceKind.securityAssessment.displayName == "Security Assessment")
        #expect(ComplianceKind.aiGeneratedContent.displayName == "AI Generated or Synthetic Content")
        #expect(ComplianceKind.unrecognized(formName: "MEDICALDEV0001").displayName == "MEDICALDEV0001")
    }

    @Test func `should write each kind as one word in JSON and read it back`() throws {
        let kinds: [ComplianceKind] = [.securityAssessment, .aiGeneratedContent, .unrecognized(formName: "MEDICALDEV0001")]

        let json = String(decoding: try JSONEncoder().encode(kinds), as: UTF8.self)

        #expect(json == #"["SECURITY_ASSESSMENT","AI_GENERATED_CONTENT","MEDICALDEV0001"]"#)
        #expect(try JSONDecoder().decode([ComplianceKind].self, from: Data(json.utf8)) == kinds)
    }
}
