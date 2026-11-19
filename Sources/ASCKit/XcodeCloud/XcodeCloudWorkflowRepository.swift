import Mockable

@Mockable
public protocol XcodeCloudWorkflowRepository: Sendable {
    func listWorkflows(productId: String) async throws -> [XcodeCloudWorkflow]
}
