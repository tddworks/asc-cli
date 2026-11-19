import Mockable

@Mockable
public protocol XcodeCloudProductRepository: Sendable {
    func listProducts(appId: String?) async throws -> [XcodeCloudProduct]
}
