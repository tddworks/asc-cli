import Foundation
@preconcurrency import AppStoreConnect_Swift_SDK

public struct SDKInAppPurchaseOfferCodes: InAppPurchaseOfferCodes, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    // MARK: - Offer Codes

    public func listOfferCodes(iapId: String) async throws -> [ASCKit.InAppPurchaseOfferCode] {
        let request = APIEndpoint.v2.inAppPurchases.id(iapId).offerCodes.get()
        let response = try await client.request(request)
        return response.data.map { mapOfferCode($0, iapId: iapId) }
    }

    public func createOfferCode(
        iapId: String,
        name: String,
        customerEligibilities: [ASCKit.IAPCustomerEligibility],
        prices: [ASCKit.OfferCodePriceInput]
    ) async throws -> ASCKit.InAppPurchaseOfferCode {
        let sdkEligibilities = customerEligibilities.compactMap {
            InAppPurchaseOfferCodeCreateRequest.Data.Attributes.CustomerEligibility(rawValue: $0.rawValue)
        }

        // Each price needs a placeholder id that correlates between `included[]` and
        // `relationships.prices.data` — ASC reads the placeholders and replaces them with
        // generated server-side ids. Mirrors the iOS app's offer-code create payload.
        let pricesPayload: [(localId: String, input: ASCKit.OfferCodePriceInput)] = prices.enumerated().map {
            (localId: "${local-price-\($0.offset + 1)}", input: $0.element)
        }
        let pricesRelationship = pricesPayload.map {
            InAppPurchaseOfferCodeCreateRequest.Data.Relationships.Prices.Datum(
                type: .inAppPurchaseOfferPrices, id: $0.localId
            )
        }
        let included: [InAppPurchaseOfferPriceInlineCreate] = pricesPayload.map { entry in
            InAppPurchaseOfferPriceInlineCreate(
                type: .inAppPurchaseOfferPrices,
                id: entry.localId,
                relationships: .init(
                    territory: .init(data: .init(type: .territories, id: entry.input.territory)),
                    pricePoint: entry.input.pricePointId.map {
                        .init(data: .init(type: .inAppPurchasePricePoints, id: $0))
                    }
                )
            )
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
                    prices: .init(data: pricesRelationship)
                )
            ),
            included: included.isEmpty ? nil : included
        )
        let response = try await client.request(APIEndpoint.v1.inAppPurchaseOfferCodes.post(body))
        return mapOfferCode(response.data, iapId: iapId)
    }

    public func updateOfferCode(offerCodeId: String, isActive: Bool) async throws -> ASCKit.InAppPurchaseOfferCode {
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

    public func listPrices(offerCodeId: String) async throws -> [ASCKit.InAppPurchaseOfferCodePrice] {
        // One price per territory — follow every page to get all 175. `include` makes Apple
        // return each price's territory and price point linkage, which the mapper reads.
        let pages = try await client.requestAllPages(
            APIEndpoint.v1.inAppPurchaseOfferCodes.id(offerCodeId).prices.get(parameters: .init(limit: 200, include: [.territory, .pricePoint])),
            nextCursor: { $0.meta?.paging.nextCursor }
        )
        return pages.flatMap(\.data).map { mapPrice($0, offerCodeId: offerCodeId) }
    }

    // MARK: - Custom Codes

    public func listCustomCodes(offerCodeId: String) async throws -> [ASCKit.InAppPurchaseOfferCodeCustomCode] {
        let request = APIEndpoint.v1.inAppPurchaseOfferCodes.id(offerCodeId).customCodes.get()
        let response = try await client.request(request)
        return response.data.map { mapCustomCode($0, offerCodeId: offerCodeId) }
    }

    public func createCustomCode(
        offerCodeId: String,
        customCode: String,
        numberOfCodes: Int,
        expirationDate: String?
    ) async throws -> ASCKit.InAppPurchaseOfferCodeCustomCode {
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

    public func updateCustomCode(customCodeId: String, isActive: Bool) async throws -> ASCKit.InAppPurchaseOfferCodeCustomCode {
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

    public func listOneTimeUseCodes(offerCodeId: String) async throws -> [ASCKit.InAppPurchaseOfferCodeOneTimeUseCode] {
        let request = APIEndpoint.v1.inAppPurchaseOfferCodes.id(offerCodeId).oneTimeUseCodes.get()
        let response = try await client.request(request)
        return response.data.map { mapOneTimeUseCode($0, offerCodeId: offerCodeId) }
    }

    public func createOneTimeUseCode(
        offerCodeId: String,
        numberOfCodes: Int,
        expirationDate: String,
        environment: ASCKit.OfferCodeEnvironment
    ) async throws -> ASCKit.InAppPurchaseOfferCodeOneTimeUseCode {
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

    public func updateOneTimeUseCode(oneTimeCodeId: String, isActive: Bool) async throws -> ASCKit.InAppPurchaseOfferCodeOneTimeUseCode {
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
    ) -> ASCKit.InAppPurchaseOfferCode {
        let customerEligibilities = (sdk.attributes?.customerEligibilities ?? []).compactMap { sdkEligibility -> ASCKit.IAPCustomerEligibility? in
            ASCKit.IAPCustomerEligibility(rawValue: sdkEligibility.rawValue)
        }

        return ASCKit.InAppPurchaseOfferCode(
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
    ) -> ASCKit.InAppPurchaseOfferCodeCustomCode {
        let createdDateString: String? = sdk.attributes?.createdDate.map { ISO8601DateFormatter().string(from: $0) }

        return ASCKit.InAppPurchaseOfferCodeCustomCode(
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
    ) -> ASCKit.InAppPurchaseOfferCodePrice {
        ASCKit.InAppPurchaseOfferCodePrice(
            id: sdk.id,
            offerCodeId: offerCodeId,
            territory: sdk.relationships?.territory?.data?.id,
            pricePointId: sdk.relationships?.pricePoint?.data?.id
        )
    }

    private func mapOneTimeUseCode(
        _ sdk: AppStoreConnect_Swift_SDK.InAppPurchaseOfferCodeOneTimeUseCode,
        offerCodeId: String
    ) -> ASCKit.InAppPurchaseOfferCodeOneTimeUseCode {
        let createdDateString: String? = sdk.attributes?.createdDate.map { ISO8601DateFormatter().string(from: $0) }
        let environment: ASCKit.OfferCodeEnvironment? = sdk.attributes?.environment.flatMap {
            ASCKit.OfferCodeEnvironment(rawValue: $0.rawValue)
        }

        return ASCKit.InAppPurchaseOfferCodeOneTimeUseCode(
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
