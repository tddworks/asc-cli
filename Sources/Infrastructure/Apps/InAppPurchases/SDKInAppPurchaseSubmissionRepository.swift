@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKInAppPurchaseSubmissionRepository: InAppPurchaseSubmissionRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func submitInAppPurchase(iapId: String) async throws -> Domain.InAppPurchaseSubmission {
        let body = InAppPurchaseSubmissionCreateRequest(data: .init(
            type: .inAppPurchaseSubmissions,
            relationships: .init(
                inAppPurchaseV2: .init(data: .init(type: .inAppPurchases, id: iapId))
            )
        ))
        let response = try await client.request(APIEndpoint.v1.inAppPurchaseSubmissions.post(body))
        return Domain.InAppPurchaseSubmission(id: response.data.id, iapId: iapId)
    }

    public func deleteSubmission(submissionId: String) async throws {
        // Generated SDK lacks DELETE /v1/inAppPurchaseSubmissions/{id}; construct manually.
        let request = Request<Void>(
            path: "/v1/inAppPurchaseSubmissions/\(submissionId)",
            method: "DELETE",
            id: "inAppPurchaseSubmissions_deleteInstance"
        )
        try await client.request(request)
    }
}
