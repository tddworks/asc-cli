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
}
