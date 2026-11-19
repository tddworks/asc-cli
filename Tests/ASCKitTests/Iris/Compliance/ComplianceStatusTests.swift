import Foundation
import Testing
@testable import ASCKit

@Suite
struct ComplianceStatusTests {
    @Test func `should show Missing Info for a requirement nobody has answered`() {
        #expect(ComplianceStatus(wireValue: "PENDING_COLLECT") == .missingInfo)
    }

    @Test func `should be pending verification while Apple checks a Yes`() {
        #expect(ComplianceStatus(wireValue: "COLLECTED_VERIFY_PENDING") == .pendingVerification)
    }

    @Test func `should be active once an answer needs no verification`() {
        #expect(ComplianceStatus(wireValue: "COLLECTED_VERIFY_NOT_NECESSARY") == .active)
    }

    @Test func `should keep a status it has not seen, never guessing`() {
        #expect(ComplianceStatus(wireValue: "COLLECTED_VERIFY_REJECTED") == .unrecognized(wireValue: "COLLECTED_VERIFY_REJECTED"))
    }

    @Test func `should let the app stay on sale only while active`() {
        #expect(ComplianceStatus.active.isActive == true)
        #expect(ComplianceStatus.missingInfo.isActive == false)
        #expect(ComplianceStatus.pendingVerification.isActive == false)
    }

    @Test func `should need the developer's action when info is missing or verification failed`() {
        #expect(ComplianceStatus.missingInfo.needsAction == true)
        #expect(ComplianceStatus.verificationFailed.needsAction == true)
        #expect(ComplianceStatus.active.needsAction == false)
        #expect(ComplianceStatus.pendingVerification.needsAction == false)
    }

    @Test func `should be named as the STATUS column names it`() {
        #expect(ComplianceStatus.missingInfo.displayName == "Missing Info")
        #expect(ComplianceStatus.pendingVerification.displayName == "Pending Verification")
        #expect(ComplianceStatus.verificationFailed.displayName == "Verification Failed")
        #expect(ComplianceStatus.active.displayName == "Active")
        #expect(ComplianceStatus.unrecognized(wireValue: "NEW_STATE").displayName == "NEW_STATE")
    }

    @Test func `should write each status as one word in JSON and read it back`() throws {
        let statuses: [ComplianceStatus] = [.missingInfo, .pendingVerification, .verificationFailed, .active, .unrecognized(wireValue: "NEW_STATE")]

        let json = String(decoding: try JSONEncoder().encode(statuses), as: UTF8.self)

        #expect(json == #"["MISSING_INFO","PENDING_VERIFICATION","VERIFICATION_FAILED","ACTIVE","NEW_STATE"]"#)
        #expect(try JSONDecoder().decode([ComplianceStatus].self, from: Data(json.utf8)) == statuses)
    }
}
