import Foundation
import Testing
@testable import ASCKit

@Suite
struct VersionReadinessTests {

    // MARK: - ReadinessCheck

    @Test func `readiness check pass factory omits message`() {
        let check = ReadinessCheck.pass()
        #expect(check.pass == true)
        #expect(check.message == nil)
    }

    @Test func `readiness check fail factory stores message`() {
        let check = ReadinessCheck.fail("No build linked")
        #expect(check.pass == false)
        #expect(check.message == "No build linked")
    }

    // MARK: - BuildReadinessCheck

    @Test func `build readiness check pass when all true`() {
        let check = BuildReadinessCheck(linked: true, valid: true, notExpired: true, buildVersion: "1.0 (1)")
        #expect(check.pass == true)
    }

    @Test func `build readiness check fails when not linked`() {
        let check = BuildReadinessCheck(linked: false, valid: true, notExpired: true)
        #expect(check.pass == false)
    }

    @Test func `build readiness check fails when invalid`() {
        let check = BuildReadinessCheck(linked: true, valid: false, notExpired: true)
        #expect(check.pass == false)
    }

    @Test func `build readiness check fails when expired`() {
        let check = BuildReadinessCheck(linked: true, valid: true, notExpired: false)
        #expect(check.pass == false)
    }

    // MARK: - LocalizationReadiness

    @Test func `localization readiness passes when description and screenshots present`() {
        let loc = LocalizationReadiness(
            locale: "en-US",
            isPrimary: true,
            hasDescription: true,
            hasKeywords: false,
            hasSupportUrl: false,
            hasWhatsNew: false,
            screenshotSetCount: 2
        )
        #expect(loc.pass == true)
    }

    @Test func `localization readiness fails when no description`() {
        let loc = LocalizationReadiness(
            locale: "en-US",
            isPrimary: true,
            hasDescription: false,
            hasKeywords: true,
            hasSupportUrl: true,
            hasWhatsNew: true,
            screenshotSetCount: 3
        )
        #expect(loc.pass == false)
    }

    @Test func `localization readiness fails when no screenshot sets`() {
        let loc = LocalizationReadiness(
            locale: "en-US",
            isPrimary: true,
            hasDescription: true,
            hasKeywords: true,
            hasSupportUrl: true,
            hasWhatsNew: true,
            screenshotSetCount: 0
        )
        #expect(loc.pass == false)
    }

    // MARK: - VersionReadiness affordances

    @Test func `version readiness affordances include checkReadiness and listLocalizations always`() {
        let readiness = MockRepositoryFactory.makeVersionReadiness(id: "v-99", isReadyToSubmit: false)
        #expect(readiness.affordances["checkReadiness"] == "asc versions check-readiness --version-id v-99")
        #expect(readiness.affordances["listLocalizations"] == "asc version-localizations list --version-id v-99")
    }

    @Test func `version readiness affordances include submit only when ready`() {
        let ready = MockRepositoryFactory.makeVersionReadiness(id: "v-1", isReadyToSubmit: true)
        let notReady = MockRepositoryFactory.makeVersionReadiness(id: "v-2", isReadyToSubmit: false)
        #expect(ready.affordances["submit"] == "asc versions submit --version-id v-1")
        #expect(notReady.affordances["submit"] == nil)
    }

    // MARK: - isReadyToSubmit

    @Test func `version readiness is not ready when state check fails`() {
        let readiness = MockRepositoryFactory.makeVersionReadiness(
            isReadyToSubmit: false,
            stateCheck: .fail("state is READY_FOR_SALE")
        )
        #expect(readiness.isReadyToSubmit == false)
    }

    // MARK: - Codable round-trip

    @Test func `version readiness codable round-trip preserves all fields`() throws {
        let readiness = MockRepositoryFactory.makeVersionReadiness(
            id: "v-rt",
            appId: "app-rt",
            versionString: "2.0.0",
            state: .prepareForSubmission,
            isReadyToSubmit: true,
            localizationCheck: LocalizationReadinessCheck(localizations: [
                LocalizationReadiness(
                    locale: "en-US",
                    isPrimary: true,
                    hasDescription: true,
                    hasKeywords: true,
                    hasSupportUrl: false,
                    hasWhatsNew: false,
                    screenshotSetCount: 1
                )
            ])
        )
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(readiness)
        let decoded = try decoder.decode(VersionReadiness.self, from: data)
        #expect(decoded == readiness)
    }

    @Test func `readiness check nil message is omitted from JSON`() throws {
        let check = ReadinessCheck.pass()
        let data = try JSONEncoder().encode(check)
        let json = String(data: data, encoding: .utf8)!
        #expect(!json.contains("message"))
    }

    @Test func `build readiness check encodes pass computed property`() throws {
        let check = BuildReadinessCheck(linked: true, valid: true, notExpired: true, buildVersion: "1.0 (1)")
        let data = try JSONEncoder().encode(check)
        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("\"pass\":true"))
    }
}
