/// REST route registrations for IAP children.
extension RESTPathResolver {
    static let _iapRoutes: Void = {
        registerRoute(command: "iap-localizations", parentParam: "iap-id", parentSegment: "iap", segment: "localizations")
        registerRoute(command: "iap-offer-codes", parentParam: "iap-id", parentSegment: "iap", segment: "offer-codes")
        registerRoute(command: "iap-offer-code-one-time-codes", parentParam: "offer-code-id", parentSegment: "iap-offer-codes", segment: "one-time-codes")
        registerRoute(command: "iap-offer-code-custom-codes", parentParam: "offer-code-id", parentSegment: "iap-offer-codes", segment: "custom-codes")
        registerRoute(command: "iap-availability", parentParam: "iap-id", parentSegment: "iap", segment: "availability")
        // Nested CLI subcommand `asc iap price-points` is registered with a space so the
        // `Affordance.cliCommand` and resolver paths agree on the same key.
        registerRoute(command: "iap price-points", parentParam: "iap-id", parentSegment: "iap", segment: "price-points")
        registerRoute(command: "iap prices", parentParam: "iap-id", parentSegment: "iap", segment: "prices")
        registerRoute(command: "iap-price-schedule", parentParam: "iap-id", parentSegment: "iap", segment: "price-schedule")
        registerRoute(command: "iap-equalizations", parentParam: "price-point-id", parentSegment: "iap-price-points", segment: "equalizations")
        // Iris-only IAP submission path. Mirrors the controller route exactly:
        //   POST /api/v1/iris/iap/:iapId/submissions
        // Multi-segment `parentSegment` is fine — `RESTPathResolver.resolve` does
        // straight string concat and produces the right URL for the registered
        // `iris iap-submissions` create affordance.
        registerRoute(command: "iris iap-submissions", parentParam: "iap-id", parentSegment: "iris/iap", segment: "submissions")
    }()
}
