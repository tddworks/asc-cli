import Foundation
import Testing
@testable import Domain

@Suite
struct BuildTests {

    @Test
    func `valid non-expired build is usable`() {
        let build = Build(id: "1", version: "1.0", expired: false, processingState: .valid)
        #expect(build.isUsable == true)
    }

    @Test
    func `expired build is not usable`() {
        let build = Build(id: "1", version: "1.0", expired: true, processingState: .valid)
        #expect(build.isUsable == false)
    }

    @Test
    func `processing build is not usable`() {
        let build = Build(id: "1", version: "1.0", expired: false, processingState: .processing)
        #expect(build.isUsable == false)
    }

    @Test
    func `failed build is not usable`() {
        let build = Build(id: "1", version: "1.0", expired: false, processingState: .failed)
        #expect(build.isUsable == false)
    }

    @Test
    func `invalid build is not usable`() {
        let build = Build(id: "1", version: "1.0", expired: false, processingState: .invalid)
        #expect(build.isUsable == false)
    }

    @Test
    func `processing state raw values match API`() {
        #expect(Build.ProcessingState.processing.rawValue == "PROCESSING")
        #expect(Build.ProcessingState.failed.rawValue == "FAILED")
        #expect(Build.ProcessingState.invalid.rawValue == "INVALID")
        #expect(Build.ProcessingState.valid.rawValue == "VALID")
    }

    @Test
    func `usable build has addToTestFlight and updateBetaNotes affordances`() {
        let build = Build(id: "b-1", version: "1.0", expired: false, processingState: .valid)
        #expect(build.affordances["addToTestFlight"] == "asc builds add-beta-group --build-id b-1 --beta-group-id <beta-group-id>")
        #expect(build.affordances["updateBetaNotes"] == "asc builds update-beta-notes --build-id b-1 --locale en-US --notes <notes>")
    }

    @Test
    func `non-usable build has no affordances`() {
        #expect(Build(id: "b-1", version: "1.0", expired: false, processingState: .processing).affordances.isEmpty)
        #expect(Build(id: "b-1", version: "1.0", expired: false, processingState: .failed).affordances.isEmpty)
        #expect(Build(id: "b-1", version: "1.0", expired: false, processingState: .invalid).affordances.isEmpty)
        #expect(Build(id: "b-1", version: "1.0", expired: true,  processingState: .valid).affordances.isEmpty)
    }

    // MARK: - Platform field

    @Test
    func `build carries platform from preReleaseVersion`() {
        let build = MockRepositoryFactory.makeBuild(id: "b-1", version: "1.0", platform: .iOS)
        #expect(build.platform == .iOS)
    }

    @Test
    func `build platform is nil when not provided`() {
        let build = MockRepositoryFactory.makeBuild(id: "b-1", version: "1.0")
        #expect(build.platform == nil)
    }

    // MARK: - Encryption compliance (ITSAppUsesNonExemptEncryption)

    @Test
    func `build with no encryption compliance answer is missing compliance`() {
        let build = MockRepositoryFactory.makeBuild(id: "b-1", version: "1.0", usesNonExemptEncryption: nil)
        #expect(build.usesNonExemptEncryption == nil)
        #expect(build.isMissingEncryptionCompliance == true)
    }

    @Test
    func `build with explicit encryption compliance answer is not missing compliance`() {
        let yes = MockRepositoryFactory.makeBuild(id: "b-1", version: "1.0", usesNonExemptEncryption: true)
        let no  = MockRepositoryFactory.makeBuild(id: "b-2", version: "1.0", usesNonExemptEncryption: false)
        #expect(yes.isMissingEncryptionCompliance == false)
        #expect(no.isMissingEncryptionCompliance == false)
    }

    @Test
    func `usable build missing encryption compliance advertises setEncryptionCompliance affordance`() {
        let build = MockRepositoryFactory.makeBuild(id: "b-1", version: "1.0", usesNonExemptEncryption: nil)
        #expect(build.affordances["setEncryptionCompliance"] == "asc builds set-encryption-compliance --build-id b-1 --uses-non-exempt-encryption <true|false>")
    }

    @Test
    func `usable build with encryption compliance answered does not advertise setEncryptionCompliance`() {
        let build = MockRepositoryFactory.makeBuild(id: "b-1", version: "1.0", usesNonExemptEncryption: false)
        #expect(build.affordances["setEncryptionCompliance"] == nil)
    }

    @Test
    func `usesNonExemptEncryption is omitted from JSON when nil`() throws {
        let build = MockRepositoryFactory.makeBuild(id: "b-1", version: "1.0", usesNonExemptEncryption: nil)
        let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(build)) as! [String: Any]
        #expect(json["usesNonExemptEncryption"] == nil)
    }

    @Test
    func `usesNonExemptEncryption is encoded when present`() throws {
        let build = MockRepositoryFactory.makeBuild(id: "b-1", version: "1.0", usesNonExemptEncryption: false)
        let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(build)) as! [String: Any]
        #expect(json["usesNonExemptEncryption"] as? Bool == false)
    }
}
