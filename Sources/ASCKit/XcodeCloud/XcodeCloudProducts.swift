import Mockable

@Mockable
public protocol XcodeCloudProducts: Sendable {
    func listProducts(appId: String?) async throws -> [XcodeCloudProduct]
}
