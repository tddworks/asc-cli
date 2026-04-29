import Domain
import Foundation

/// Implements `IrisInAppPurchaseSubmissionRepository` via the iris private API.
///
/// The user-visible difference from `SDKInAppPurchaseSubmissionRepository` (public SDK)
/// is `attributes.submitWithNextAppStoreVersion` — the only place it is accepted is
/// `POST /iris/v1/inAppPurchaseSubmissions`. The public ASC SDK's
/// `InAppPurchaseSubmissionCreateRequest` lacks an `attributes` field entirely.
public struct IrisSDKInAppPurchaseSubmissionRepository: IrisInAppPurchaseSubmissionRepository, @unchecked Sendable {
    private let client: IrisClient

    public init(client: IrisClient = IrisClient()) {
        self.client = client
    }

    public func deleteSubmission(
        session: IrisSession,
        submissionId: String
    ) async throws {
        _ = try await client.delete(
            path: "inAppPurchaseSubmissions/\(submissionId)",
            cookies: session.cookies
        )
    }

    public func submitInAppPurchase(
        session: IrisSession,
        iapId: String,
        submitWithNextAppStoreVersion: Bool
    ) async throws -> IrisInAppPurchaseSubmission {
        let request = IrisInAppPurchaseSubmissionCreateRequest(
            iapId: iapId,
            submitWithNextAppStoreVersion: submitWithNextAppStoreVersion
        )
        let body = try JSONEncoder().encode(request)
        let (data, _) = try await client.post(
            path: "inAppPurchaseSubmissions",
            body: body,
            cookies: session.cookies
        )
        let response = try JSONDecoder().decode(IrisInAppPurchaseSubmissionResponse.self, from: data)
        return IrisInAppPurchaseSubmission(
            id: response.data.id,
            iapId: iapId,
            submitWithNextAppStoreVersion: submitWithNextAppStoreVersion
        )
    }
}

// MARK: - JSON:API request/response shapes

struct IrisInAppPurchaseSubmissionCreateRequest: Encodable {
    let data: SubmissionData

    init(iapId: String, submitWithNextAppStoreVersion: Bool) {
        self.data = SubmissionData(
            type: "inAppPurchaseSubmissions",
            attributes: Attributes(submitWithNextAppStoreVersion: submitWithNextAppStoreVersion),
            relationships: Relationships(
                inAppPurchaseV2: ResourceWrapper(data: ResourceRef(id: iapId, type: "inAppPurchases"))
            )
        )
    }

    struct SubmissionData: Encodable {
        let type: String
        let attributes: Attributes
        let relationships: Relationships
    }

    struct Attributes: Encodable {
        let submitWithNextAppStoreVersion: Bool
    }

    struct Relationships: Encodable {
        let inAppPurchaseV2: ResourceWrapper
    }

    struct ResourceWrapper: Encodable {
        let data: ResourceRef
    }

    struct ResourceRef: Encodable {
        let id: String
        let type: String
    }
}

struct IrisInAppPurchaseSubmissionResponse: Decodable {
    let data: ResourceData

    struct ResourceData: Decodable {
        let id: String
        let type: String
    }
}
