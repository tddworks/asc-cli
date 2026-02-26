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
}
