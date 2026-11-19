import Foundation
import Testing
@testable import ASCKit

@Suite
struct IrisCookieErrorTests {

    @Test func `noCookiesFound has descriptive message`() {
        let error = IrisCookieError.noCookiesFound
        #expect(error.errorDescription?.contains("No App Store Connect cookies found") == true)
        #expect(error.errorDescription?.contains("ASC_IRIS_COOKIES") == true)
    }
}
