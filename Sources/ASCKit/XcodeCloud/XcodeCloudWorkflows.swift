import Mockable

@Mockable
public protocol XcodeCloudWorkflows: Sendable {
    func listWorkflows(productId: String) async throws -> [XcodeCloudWorkflow]
}
