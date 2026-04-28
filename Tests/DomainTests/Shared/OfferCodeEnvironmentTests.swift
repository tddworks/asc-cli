import Foundation
import Testing
@testable import Domain

@Suite
struct OfferCodeEnvironmentTests {

    @Test func `production raw value matches API`() {
        #expect(OfferCodeEnvironment.production.rawValue == "PRODUCTION")
    }

    @Test func `sandbox raw value matches API`() {
        #expect(OfferCodeEnvironment.sandbox.rawValue == "SANDBOX")
    }

    @Test func `decodes from API string`() throws {
        let decoded = try JSONDecoder().decode(
            OfferCodeEnvironment.self,
            from: Data("\"SANDBOX\"".utf8)
        )
        #expect(decoded == .sandbox)
    }
}
