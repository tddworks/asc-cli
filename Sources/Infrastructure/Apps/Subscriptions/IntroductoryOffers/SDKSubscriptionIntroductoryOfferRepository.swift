@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKSubscriptionIntroductoryOfferRepository: SubscriptionIntroductoryOfferRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listIntroductoryOffers(subscriptionId: String) async throws -> [Domain.SubscriptionIntroductoryOffer] {
        let request = APIEndpoint.v1.subscriptions.id(subscriptionId).introductoryOffers.get()
        let response = try await client.request(request)
        return response.data.map { mapOffer($0, subscriptionId: subscriptionId) }
    }

    public func createIntroductoryOffer(
        subscriptionId: String,
        duration: Domain.SubscriptionOfferDuration,
        offerMode: Domain.SubscriptionOfferMode,
        numberOfPeriods: Int,
        startDate: String?,
        endDate: String?,
        territory: String?,
        pricePointId: String?
    ) async throws -> Domain.SubscriptionIntroductoryOffer {
        let sdkDuration = AppStoreConnect_Swift_SDK.SubscriptionOfferDuration(rawValue: duration.rawValue) ?? .oneMonth
        let sdkMode = AppStoreConnect_Swift_SDK.SubscriptionOfferMode(rawValue: offerMode.rawValue) ?? .freeTrial

        let territoryRelationship: SubscriptionIntroductoryOfferCreateRequest.Data.Relationships.Territory? =
            territory.map { .init(data: .init(type: .territories, id: $0)) }
        let pricePointRelationship: SubscriptionIntroductoryOfferCreateRequest.Data.Relationships.SubscriptionPricePoint? =
            pricePointId.map { .init(data: .init(type: .subscriptionPricePoints, id: $0)) }

        let body = SubscriptionIntroductoryOfferCreateRequest(
            data: .init(
                type: .subscriptionIntroductoryOffers,
                attributes: .init(
                    startDate: startDate,
                    endDate: endDate,
                    duration: sdkDuration,
                    offerMode: sdkMode,
                    numberOfPeriods: numberOfPeriods
                ),
                relationships: .init(
                    subscription: .init(data: .init(type: .subscriptions, id: subscriptionId)),
                    territory: territoryRelationship,
                    subscriptionPricePoint: pricePointRelationship
                )
            )
        )
        let response = try await client.request(APIEndpoint.v1.subscriptionIntroductoryOffers.post(body))
        return mapOffer(response.data, subscriptionId: subscriptionId)
    }

    public func deleteIntroductoryOffer(offerId: String) async throws {
        _ = try await client.request(APIEndpoint.v1.subscriptionIntroductoryOffers.id(offerId).delete)
    }

    private func mapOffer(
        _ sdk: AppStoreConnect_Swift_SDK.SubscriptionIntroductoryOffer,
        subscriptionId: String
    ) -> Domain.SubscriptionIntroductoryOffer {
        let durationRaw = sdk.attributes?.duration?.rawValue ?? Domain.SubscriptionOfferDuration.oneMonth.rawValue
        let duration = Domain.SubscriptionOfferDuration(rawValue: durationRaw) ?? .oneMonth
        let modeRaw = sdk.attributes?.offerMode?.rawValue ?? Domain.SubscriptionOfferMode.freeTrial.rawValue
        let offerMode = Domain.SubscriptionOfferMode(rawValue: modeRaw) ?? .freeTrial
        let territory = sdk.relationships?.territory?.data?.id

        return Domain.SubscriptionIntroductoryOffer(
            id: sdk.id,
            subscriptionId: subscriptionId,
            duration: duration,
            offerMode: offerMode,
            numberOfPeriods: sdk.attributes?.numberOfPeriods ?? 1,
            startDate: sdk.attributes?.startDate,
            endDate: sdk.attributes?.endDate,
            territory: territory
        )
    }
}
