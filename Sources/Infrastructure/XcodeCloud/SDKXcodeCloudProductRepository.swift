@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKXcodeCloudProductRepository: XcodeCloudProductRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listProducts(appId: String?) async throws -> [XcodeCloudProduct] {
        let request = APIEndpoint.v1.ciProducts.get(parameters: .init(
            filterApp: appId.map { [$0] }
        ))
        let response = try await client.request(request)
        return response.data.map { mapProduct($0) }
    }

    private func mapProduct(_ sdk: AppStoreConnect_Swift_SDK.CiProduct) -> XcodeCloudProduct {
        let appId = sdk.relationships?.app?.data?.id ?? ""
        let productType: XcodeCloudProductType = sdk.attributes?.productType == .framework ? .framework : .app
        return XcodeCloudProduct(
            id: sdk.id,
            appId: appId,
            name: sdk.attributes?.name ?? "",
            productType: productType,
            createdDate: sdk.attributes?.createdDate
        )
    }
}
