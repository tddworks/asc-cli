@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKReviewDetailRepository: ReviewDetailRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func getReviewDetail(versionId: String) async throws -> Domain.AppStoreReviewDetail {
        let request = APIEndpoint.v1.appStoreVersions.id(versionId).appStoreReviewDetail.get()
        do {
            let response = try await client.request(request)
            return mapReviewDetail(response.data, versionId: versionId)
        } catch {
            // The API returns {"data": null} when review information has never been submitted.
            // Treat as empty — reviewContactCheck will surface this as a SHOULD FIX warning.
            return Domain.AppStoreReviewDetail(id: "", versionId: versionId)
        }
    }

    public func upsertReviewDetail(versionId: String, update: Domain.ReviewDetailUpdate) async throws -> Domain.AppStoreReviewDetail {
        let existing = try await getReviewDetail(versionId: versionId)
        let attributes = makeAttributes(from: update)
        if existing.id.isEmpty {
            // No review detail exists yet — create one
            let body = AppStoreReviewDetailCreateRequest(data: .init(
                type: .appStoreReviewDetails,
                attributes: attributes,
                relationships: .init(
                    appStoreVersion: .init(data: .init(type: .appStoreVersions, id: versionId))
                )
            ))
            let response = try await client.request(APIEndpoint.v1.appStoreReviewDetails.post(body))
            return mapReviewDetail(response.data, versionId: versionId)
        } else {
            // Review detail exists — patch it
            let body = AppStoreReviewDetailUpdateRequest(data: .init(
                type: .appStoreReviewDetails,
                id: existing.id,
                attributes: .init(
                    contactFirstName: update.contactFirstName,
                    contactLastName: update.contactLastName,
                    contactPhone: update.contactPhone,
                    contactEmail: update.contactEmail,
                    demoAccountName: update.demoAccountName,
                    demoAccountPassword: update.demoAccountPassword,
                    isDemoAccountRequired: update.demoAccountRequired,
                    notes: update.notes
                )
            ))
            let response = try await client.request(APIEndpoint.v1.appStoreReviewDetails.id(existing.id).patch(body))
            return mapReviewDetail(response.data, versionId: versionId)
        }
    }

    private func makeAttributes(from update: Domain.ReviewDetailUpdate) -> AppStoreReviewDetailCreateRequest.Data.Attributes {
        AppStoreReviewDetailCreateRequest.Data.Attributes(
            contactFirstName: update.contactFirstName,
            contactLastName: update.contactLastName,
            contactPhone: update.contactPhone,
            contactEmail: update.contactEmail,
            demoAccountName: update.demoAccountName,
            demoAccountPassword: update.demoAccountPassword,
            isDemoAccountRequired: update.demoAccountRequired,
            notes: update.notes
        )
    }

    private func mapReviewDetail(
        _ sdk: AppStoreConnect_Swift_SDK.AppStoreReviewDetail,
        versionId: String
    ) -> Domain.AppStoreReviewDetail {
        Domain.AppStoreReviewDetail(
            id: sdk.id,
            versionId: versionId,
            contactFirstName: sdk.attributes?.contactFirstName,
            contactLastName: sdk.attributes?.contactLastName,
            contactPhone: sdk.attributes?.contactPhone,
            contactEmail: sdk.attributes?.contactEmail,
            demoAccountRequired: sdk.attributes?.isDemoAccountRequired ?? false,
            demoAccountName: sdk.attributes?.demoAccountName,
            demoAccountPassword: sdk.attributes?.demoAccountPassword,
            notes: sdk.attributes?.notes
        )
    }
}
