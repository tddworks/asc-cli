/// REST route registrations for app pricing (mirrors `iap price-points` / `iap prices`).
extension RESTPathResolver {
    static let _appPricingRoutes: Void = {
        registerRoute(command: "apps price-points", parentParam: "app-id", parentSegment: "apps", segment: "price-points")
        registerRoute(command: "apps prices", parentParam: "app-id", parentSegment: "apps", segment: "prices")
    }()
}
