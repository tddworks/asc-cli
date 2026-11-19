import Testing
@testable import ASCKit

@Suite
struct AppPricingTests {

    // MARK: - AppPricePoint

    @Test func `a price point in a territory offers setting the app's price to it`() {
        let point = AppPricePoint(id: "pp-1", appId: "app-1", territory: "USA", customerPrice: "4.99", proceeds: "4.24")
        #expect(point.affordances["setPrice"]
            == "asc apps prices set --app-id app-1 --base-territory USA --price-point-id pp-1")
        #expect(point.affordances["listPricePoints"] == "asc apps price-points list --app-id app-1 --territory USA")
        #expect(point.apiLinks["setPrice"]?.href == "/api/v1/apps/app-1/prices/set")
        #expect(point.apiLinks["setPrice"]?.method == "POST")
        #expect(point.apiLinks["listPricePoints"]?.href == "/api/v1/apps/app-1/price-points")
    }

    @Test func `a price point without a known territory cannot be set`() {
        let point = AppPricePoint(id: "pp-1", appId: "app-1", territory: nil, customerPrice: "4.99", proceeds: nil)
        #expect(point.affordances["setPrice"] == nil)
    }

    @Test func `the zero price point makes the app free`() {
        #expect(AppPricePoint(id: "pp-0", appId: "app-1", territory: "USA", customerPrice: "0.0", proceeds: "0.0").isFree)
        #expect(AppPricePoint(id: "pp-0", appId: "app-1", territory: "USA", customerPrice: "0", proceeds: "0").isFree)
        #expect(!AppPricePoint(id: "pp-1", appId: "app-1", territory: "USA", customerPrice: "0.99", proceeds: "0.84").isFree)
    }

    // MARK: - AppPriceSchedule

    @Test func `a new price schedule points back at the price points of its base territory`() {
        let schedule = AppPriceSchedule(id: "sched-1", appId: "app-1", baseTerritory: "USA")
        #expect(schedule.affordances["listPricePoints"] == "asc apps price-points list --app-id app-1 --territory USA")
    }

    // MARK: - App

    @Test func `an app points at its price points`() {
        let app = App(id: "app-1", name: "Unveil", bundleId: "com.onegai.unveil")
        #expect(app.affordances["listPricePoints"] == "asc apps price-points list --app-id app-1 --territory USA")
        #expect(app.apiLinks["listPricePoints"]?.href == "/api/v1/apps/app-1/price-points")
    }
}
