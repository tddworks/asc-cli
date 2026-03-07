@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKXcodeCloudWorkflowRepository: XcodeCloudWorkflowRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listWorkflows(productId: String) async throws -> [XcodeCloudWorkflow] {
        let request = APIEndpoint.v1.ciProducts.id(productId).workflows.get()
        let response = try await client.request(request)
        return response.data.map { mapWorkflow($0, productId: productId) }
    }

    private func mapWorkflow(_ sdk: AppStoreConnect_Swift_SDK.CiWorkflow, productId: String) -> XcodeCloudWorkflow {
        XcodeCloudWorkflow(
            id: sdk.id,
            productId: productId,
            name: sdk.attributes?.name ?? "",
            description: sdk.attributes?.description,
            isEnabled: sdk.attributes?.isEnabled ?? false,
            isLockedForEditing: sdk.attributes?.isLockedForEditing ?? false,
            containerFilePath: sdk.attributes?.containerFilePath
        )
    }
}
