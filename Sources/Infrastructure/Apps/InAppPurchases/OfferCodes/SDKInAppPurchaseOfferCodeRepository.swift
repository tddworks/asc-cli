import Foundation
@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKInAppPurchaseOfferCodeRepository: InAppPurchaseOfferCodeRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    // MARK: - Offer Codes

    public func listOfferCodes(iapId: String) async throws -> [Domain.InAppPurchaseOfferCode] {
        let request = APIEndpoint.v2.inAppPurchases.id(iapId).offerCodes.get()
        let response = try await client.request(request)
        return response.data.map { mapOfferCode($0, iapId: iapId) }
    }

    public func createOfferCode(
        iapId: String,
        name: String,
        customerEligibilities: [Domain.IAPCustomerEligibility]
    ) async throws -> Domain.InAppPurchaseOfferCode {
        let sdkEligibilities = customerEligibilities.compactMap {
            InAppPurchaseOfferCodeCreateRequest.Data.Attributes.CustomerEligibility(rawValue: $0.rawValue)
        }

        let body = InAppPurchaseOfferCodeCreateRequest(
            data: .init(
                type: .inAppPurchaseOfferCodes,
                attributes: .init(
                    name: name,
                    customerEligibilities: sdkEligibilities
                ),
                relationships: .init(
                    inAppPurchase: .init(data: .init(type: .inAppPurchases, id: iapId)),
                    prices: .init(data: [])
                )
            )
        )
        let response = try await client.request(APIEndpoint.v1.inAppPurchaseOfferCodes.post(body))
        return mapOfferCode(response.data, iapId: iapId)
    }

    public func updateOfferCode(offerCodeId: String, isActive: Bool) async throws -> Domain.InAppPurchaseOfferCode {
        let body = InAppPurchaseOfferCodeUpdateRequest(
            data: .init(
                type: .inAppPurchaseOfferCodes,
                id: offerCodeId,
                attributes: .init(isActive: isActive)
            )
        )
        let response = try await client.request(APIEndpoint.v1.inAppPurchaseOfferCodes.id(offerCodeId).patch(body))
        return mapOfferCode(response.data, iapId: "")
    }

    // MARK: - Prices

    public func listPrices(offerCodeId: String) async throws -> [Domain.InAppPurchaseOfferCodePrice] {
        let request = APIEndpoint.v1.inAppPurchaseOfferCodes.id(offerCodeId).prices.get()
        let response = try await client.request(request)
        return response.data.map { mapPrice($0, offerCodeId: offerCodeId) }
    }

    // MARK: - Custom Codes

    public func listCustomCodes(offerCodeId: String) async throws -> [Domain.InAppPurchaseOfferCodeCustomCode] {
        let request = APIEndpoint.v1.inAppPurchaseOfferCodes.id(offerCodeId).customCodes.get()
        let response = try await client.request(request)
        return response.data.map { mapCustomCode($0, offerCodeId: offerCodeId) }
    }

    public func createCustomCode(
        offerCodeId: String,
        customCode: String,
        numberOfCodes: Int,
        expirationDate: String?
    ) async throws -> Domain.InAppPurchaseOfferCodeCustomCode {
        let body = InAppPurchaseOfferCodeCustomCodeCreateRequest(
            data: .init(
                type: .inAppPurchaseOfferCodeCustomCodes,
                attributes: .init(
                    customCode: customCode,
                    numberOfCodes: numberOfCodes,
                    expirationDate: expirationDate
                ),
                relationships: .init(
                    offerCode: .init(data: .init(type: .inAppPurchaseOfferCodes, id: offerCodeId))
                )
            )
        )
        let response = try await client.request(APIEndpoint.v1.inAppPurchaseOfferCodeCustomCodes.post(body))
        return mapCustomCode(response.data, offerCodeId: offerCodeId)
    }

    public func updateCustomCode(customCodeId: String, isActive: Bool) async throws -> Domain.InAppPurchaseOfferCodeCustomCode {
        let body = InAppPurchaseOfferCodeCustomCodeUpdateRequest(
            data: .init(
                type: .inAppPurchaseOfferCodeCustomCodes,
                id: customCodeId,
                attributes: .init(isActive: isActive)
            )
        )
        let response = try await client.request(APIEndpoint.v1.inAppPurchaseOfferCodeCustomCodes.id(customCodeId).patch(body))
        return mapCustomCode(response.data, offerCodeId: "")
    }

    // MARK: - One-Time Use Codes

    public func listOneTimeUseCodes(offerCodeId: String) async throws -> [Domain.InAppPurchaseOfferCodeOneTimeUseCode] {
        let request = APIEndpoint.v1.inAppPurchaseOfferCodes.id(offerCodeId).oneTimeUseCodes.get()
        let response = try await client.request(request)
        return response.data.map { mapOneTimeUseCode($0, offerCodeId: offerCodeId) }
    }

    public func createOneTimeUseCode(
        offerCodeId: String,
        numberOfCodes: Int,
        expirationDate: String,
        environment: Domain.OfferCodeEnvironment
    ) async throws -> Domain.InAppPurchaseOfferCodeOneTimeUseCode {
        let sdkEnv = AppStoreConnect_Swift_SDK.OfferCodeEnvironment(rawValue: environment.rawValue)
        let body = InAppPurchaseOfferCodeOneTimeUseCodeCreateRequest(
            data: .init(
                type: .inAppPurchaseOfferCodeOneTimeUseCodes,
                attributes: .init(
                    numberOfCodes: numberOfCodes,
                    expirationDate: expirationDate,
                    environment: sdkEnv
                ),
                relationships: .init(
                    offerCode: .init(data: .init(type: .inAppPurchaseOfferCodes, id: offerCodeId))
                )
            )
        )
        let response = try await client.request(APIEndpoint.v1.inAppPurchaseOfferCodeOneTimeUseCodes.post(body))
        return mapOneTimeUseCode(response.data, offerCodeId: offerCodeId)
    }

    public func updateOneTimeUseCode(oneTimeCodeId: String, isActive: Bool) async throws -> Domain.InAppPurchaseOfferCodeOneTimeUseCode {
        let body = InAppPurchaseOfferCodeOneTimeUseCodeUpdateRequest(
            data: .init(
                type: .inAppPurchaseOfferCodeOneTimeUseCodes,
                id: oneTimeCodeId,
                attributes: .init(isActive: isActive)
            )
        )
        let response = try await client.request(APIEndpoint.v1.inAppPurchaseOfferCodeOneTimeUseCodes.id(oneTimeCodeId).patch(body))
        return mapOneTimeUseCode(response.data, offerCodeId: "")
    }

    public func fetchOneTimeUseCodeValues(oneTimeCodeId: String) async throws -> String {
        let request = APIEndpoint.v1.inAppPurchaseOfferCodeOneTimeUseCodes.id(oneTimeCodeId).values.get
        return try await client.request(request)
    }

    // MARK: - Mappers

    private func mapOfferCode(
        _ sdk: AppStoreConnect_Swift_SDK.InAppPurchaseOfferCode,
        iapId: String
    ) -> Domain.InAppPurchaseOfferCode {
        let customerEligibilities = (sdk.attributes?.customerEligibilities ?? []).compactMap { sdkEligibility -> Domain.IAPCustomerEligibility? in
            Domain.IAPCustomerEligibility(rawValue: sdkEligibility.rawValue)
        }

        return Domain.InAppPurchaseOfferCode(
            id: sdk.id,
            iapId: iapId,
            name: sdk.attributes?.name ?? "",
            customerEligibilities: customerEligibilities,
            isActive: sdk.attributes?.isActive ?? false,
            totalNumberOfCodes: nil,
            productionCodeCount: sdk.attributes?.productionCodeCount,
            sandboxCodeCount: sdk.attributes?.sandboxCodeCount
        )
    }

    private func mapCustomCode(
        _ sdk: AppStoreConnect_Swift_SDK.InAppPurchaseOfferCodeCustomCode,
        offerCodeId: String
    ) -> Domain.InAppPurchaseOfferCodeCustomCode {
        let createdDateString: String? = sdk.attributes?.createdDate.map { ISO8601DateFormatter().string(from: $0) }

        return Domain.InAppPurchaseOfferCodeCustomCode(
            id: sdk.id,
            offerCodeId: offerCodeId,
            customCode: sdk.attributes?.customCode ?? "",
            numberOfCodes: sdk.attributes?.numberOfCodes ?? 0,
            createdDate: createdDateString,
            expirationDate: sdk.attributes?.expirationDate,
            isActive: sdk.attributes?.isActive ?? false
        )
    }

    private func mapPrice(
        _ sdk: AppStoreConnect_Swift_SDK.InAppPurchaseOfferPrice,
        offerCodeId: String
    ) -> Domain.InAppPurchaseOfferCodePrice {
        Domain.InAppPurchaseOfferCodePrice(
            id: sdk.id,
            offerCodeId: offerCodeId,
            territory: sdk.relationships?.territory?.data?.id,
            pricePointId: sdk.relationships?.pricePoint?.data?.id
        )
    }

    private func mapOneTimeUseCode(
        _ sdk: AppStoreConnect_Swift_SDK.InAppPurchaseOfferCodeOneTimeUseCode,
        offerCodeId: String
    ) -> Domain.InAppPurchaseOfferCodeOneTimeUseCode {
        let createdDateString: String? = sdk.attributes?.createdDate.map { ISO8601DateFormatter().string(from: $0) }
        let environment: Domain.OfferCodeEnvironment? = sdk.attributes?.environment.flatMap {
            Domain.OfferCodeEnvironment(rawValue: $0.rawValue)
        }

        return Domain.InAppPurchaseOfferCodeOneTimeUseCode(
            id: sdk.id,
            offerCodeId: offerCodeId,
            numberOfCodes: sdk.attributes?.numberOfCodes ?? 0,
            createdDate: createdDateString,
            expirationDate: sdk.attributes?.expirationDate,
            isActive: sdk.attributes?.isActive ?? false,
            environment: environment
        )
    }
}
