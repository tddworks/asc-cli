/// REST route registrations for product versions.
extension RESTPathResolver {
    static let _productVersionRoutes: Void = {
        registerRoute(command: "iap versions", parentParam: "iap-id", parentSegment: "iap", segment: "versions")
        registerRoute(command: "subscriptions versions", parentParam: "subscription-id", parentSegment: "subscriptions", segment: "versions")
        registerRoute(command: "subscription-groups versions", parentParam: "group-id", parentSegment: "subscription-groups", segment: "versions")
    }()
}
