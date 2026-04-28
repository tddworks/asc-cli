import Foundation
import Testing
@testable import Domain

@Suite
struct OfferCodePriceInputTests {

    @Test func `paid price carries territory and pricePointId`() {
        let input = OfferCodePriceInput(territory: "USA", pricePointId: "pp-1")
        #expect(input.territory == "USA")
        #expect(input.pricePointId == "pp-1")
    }

    @Test func `free price has territory but nil pricePointId`() {
        let input = OfferCodePriceInput(territory: "JPN", pricePointId: nil)
        #expect(input.territory == "JPN")
        #expect(input.pricePointId == nil)
    }

    @Test func `isFree returns true when pricePointId is nil`() {
        #expect(OfferCodePriceInput(territory: "USA", pricePointId: nil).isFree)
        #expect(!OfferCodePriceInput(territory: "USA", pricePointId: "pp-1").isFree)
    }
}
