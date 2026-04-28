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
    }()
}
