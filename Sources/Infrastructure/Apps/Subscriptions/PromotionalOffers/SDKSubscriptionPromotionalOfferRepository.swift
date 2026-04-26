@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKSubscriptionPromotionalOfferRepository: SubscriptionPromotionalOfferRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listPromotionalOffers(subscriptionId: String) async throws -> [Domain.SubscriptionPromotionalOffer] {
        let request = APIEndpoint.v1.subscriptions.id(subscriptionId).promotionalOffers.get()
        let response = try await client.request(request)
        return response.data.map { mapOffer($0, subscriptionId: subscriptionId) }
    }

    public func createPromotionalOffer(
        subscriptionId: String,
        name: String,
        offerCode: String,
        duration: Domain.SubscriptionOfferDuration,
        offerMode: Domain.SubscriptionOfferMode,
        numberOfPeriods: Int,
        prices: [Domain.PromotionalOfferPriceInput]
    ) async throws -> Domain.SubscriptionPromotionalOffer {
        let sdkDuration = AppStoreConnect_Swift_SDK.SubscriptionOfferDuration(rawValue: duration.rawValue) ?? .oneMonth
        let sdkMode = AppStoreConnect_Swift_SDK.SubscriptionOfferMode(rawValue: offerMode.rawValue) ?? .freeTrial

        // Use ${newPromoOfferPrice-N} 1-based local IDs to match the ASC web pattern
        // and avoid 409 ENTITY_ERROR.INCLUDED.INVALID_ID errors.
        let priceIds = prices.indices.map { "${newPromoOfferPrice-\($0 + 1)}" }
        let priceRelations: [SubscriptionPromotionalOfferCreateRequest.Data.Relationships.Prices.Datum] = priceIds.map {
            .init(type: .subscriptionPromotionalOfferPrices, id: $0)
        }
        let included: [SubscriptionPromotionalOfferPriceInlineCreate] = zip(priceIds, prices).map { (localId, input) in
            SubscriptionPromotionalOfferPriceInlineCreate(
                type: .subscriptionPromotionalOfferPrices,
                id: localId,
                relationships: .init(
                    territory: .init(data: .init(type: .territories, id: input.territory)),
                    subscriptionPricePoint: .init(data: .init(type: .subscriptionPricePoints, id: input.pricePointId))
                )
            )
        }

        let body = SubscriptionPromotionalOfferCreateRequest(
            data: .init(
                type: .subscriptionPromotionalOffers,
                attributes: .init(
                    duration: sdkDuration,
                    name: name,
                    numberOfPeriods: numberOfPeriods,
                    offerCode: offerCode,
                    offerMode: sdkMode
                ),
                relationships: .init(
                    subscription: .init(data: .init(type: .subscriptions, id: subscriptionId)),
                    prices: .init(data: priceRelations)
                )
            ),
            included: included.isEmpty ? nil : included
        )
        let response = try await client.request(APIEndpoint.v1.subscriptionPromotionalOffers.post(body))
        return mapOffer(response.data, subscriptionId: subscriptionId)
    }

    public func deletePromotionalOffer(offerId: String) async throws {
        _ = try await client.request(APIEndpoint.v1.subscriptionPromotionalOffers.id(offerId).delete)
    }

    public func listPrices(offerId: String) async throws -> [Domain.SubscriptionPromotionalOfferPrice] {
        let request = APIEndpoint.v1.subscriptionPromotionalOffers.id(offerId).prices.get()
        let response = try await client.request(request)
        return response.data.map { mapPrice($0, offerId: offerId) }
    }

    private func mapOffer(
        _ sdk: AppStoreConnect_Swift_SDK.SubscriptionPromotionalOffer,
        subscriptionId: String
    ) -> Domain.SubscriptionPromotionalOffer {
        let durationRaw = sdk.attributes?.duration?.rawValue ?? Domain.SubscriptionOfferDuration.oneMonth.rawValue
        let duration = Domain.SubscriptionOfferDuration(rawValue: durationRaw) ?? .oneMonth
        let modeRaw = sdk.attributes?.offerMode?.rawValue ?? Domain.SubscriptionOfferMode.freeTrial.rawValue
        let mode = Domain.SubscriptionOfferMode(rawValue: modeRaw) ?? .freeTrial

        return Domain.SubscriptionPromotionalOffer(
            id: sdk.id,
            subscriptionId: subscriptionId,
            name: sdk.attributes?.name ?? "",
            offerCode: sdk.attributes?.offerCode ?? "",
            duration: duration,
            offerMode: mode,
            numberOfPeriods: sdk.attributes?.numberOfPeriods ?? 1
        )
    }

    private func mapPrice(
        _ sdk: AppStoreConnect_Swift_SDK.SubscriptionPromotionalOfferPrice,
        offerId: String
    ) -> Domain.SubscriptionPromotionalOfferPrice {
        Domain.SubscriptionPromotionalOfferPrice(
            id: sdk.id,
            offerId: offerId,
            territory: sdk.relationships?.territory?.data?.id,
            subscriptionPricePointId: sdk.relationships?.subscriptionPricePoint?.data?.id
        )
    }
}
