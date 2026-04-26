@preconcurrency import AppStoreConnect_Swift_SDK
import Domain
import Foundation

public struct SDKWinBackOfferRepository: WinBackOfferRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listWinBackOffers(subscriptionId: String) async throws -> [Domain.WinBackOffer] {
        let request = APIEndpoint.v1.subscriptions.id(subscriptionId).winBackOffers.get()
        let response = try await client.request(request)
        return response.data.map { mapOffer($0, subscriptionId: subscriptionId) }
    }

    public func createWinBackOffer(
        subscriptionId: String,
        referenceName: String,
        offerId: String,
        duration: Domain.SubscriptionOfferDuration,
        offerMode: Domain.SubscriptionOfferMode,
        periodCount: Int,
        paidSubscriptionDurationInMonths: Int,
        timeSinceLastSubscribedMin: Int,
        timeSinceLastSubscribedMax: Int,
        waitBetweenOffersInMonths: Int?,
        startDate: String,
        endDate: String?,
        priority: Domain.WinBackOfferPriority,
        promotionIntent: Domain.WinBackOfferPromotionIntent?,
        prices: [Domain.WinBackOfferPriceInput]
    ) async throws -> Domain.WinBackOffer {
        // The generated SDK's `WinBackOfferPriceInlineCreate` lacks territory + pricePoint
        // relationships, so we build the body by hand. ASC web uses 1-based ${newPromoOfferPrice-N}
        // local IDs in the included[] array.
        let priceLocalIds = prices.indices.map { "${newPromoOfferPrice-\($0 + 1)}" }

        let priceData: [[String: AnyCodable]] = priceLocalIds.map {
            ["type": .string("winBackOfferPrices"), "id": .string($0)]
        }
        let included: [[String: AnyCodable]] = zip(priceLocalIds, prices).map { (localId, input) in
            [
                "type": .string("winBackOfferPrices"),
                "id": .string(localId),
                "relationships": .object([
                    "territory": .object([
                        "data": .object([
                            "type": .string("territories"),
                            "id": .string(input.territory),
                        ])
                    ]),
                    "subscriptionPricePoint": .object([
                        "data": .object([
                            "type": .string("subscriptionPricePoints"),
                            "id": .string(input.pricePointId),
                        ])
                    ]),
                ]),
            ]
        }

        var attributes: [String: AnyCodable] = [
            "referenceName": .string(referenceName),
            "offerId": .string(offerId),
            "duration": .string(duration.rawValue),
            "offerMode": .string(offerMode.rawValue),
            "periodCount": .int(periodCount),
            "customerEligibilityPaidSubscriptionDurationInMonths": .int(paidSubscriptionDurationInMonths),
            "customerEligibilityTimeSinceLastSubscribedInMonths": .object([
                "minimum": .int(timeSinceLastSubscribedMin),
                "maximum": .int(timeSinceLastSubscribedMax),
            ]),
            "startDate": .string(startDate),
            "priority": .string(priority.rawValue),
        ]
        if let waitBetweenOffersInMonths {
            attributes["customerEligibilityWaitBetweenOffersInMonths"] = .int(waitBetweenOffersInMonths)
        }
        if let endDate {
            attributes["endDate"] = .string(endDate)
        }
        if let promotionIntent {
            attributes["promotionIntent"] = .string(promotionIntent.rawValue)
        }

        let body: [String: AnyCodable] = [
            "data": .object([
                "type": .string("winBackOffers"),
                "attributes": .object(attributes),
                "relationships": .object([
                    "subscription": .object([
                        "data": .object([
                            "type": .string("subscriptions"),
                            "id": .string(subscriptionId),
                        ])
                    ]),
                    "prices": .object([
                        "data": .array(priceData.map { .object($0) })
                    ]),
                ]),
            ]),
            "included": .array(included.map { .object($0) }),
        ]

        let request = Request<WinBackOfferResponse>(
            path: "/v1/winBackOffers",
            method: "POST",
            body: body,
            id: "winBackOffers_createInstance"
        )
        let response = try await client.request(request)
        return mapOffer(response.data, subscriptionId: subscriptionId)
    }

    public func updateWinBackOffer(
        offerId: String,
        startDate: String?,
        endDate: String?,
        priority: Domain.WinBackOfferPriority?,
        promotionIntent: Domain.WinBackOfferPromotionIntent?,
        paidSubscriptionDurationInMonths: Int?,
        timeSinceLastSubscribedMin: Int?,
        timeSinceLastSubscribedMax: Int?,
        waitBetweenOffersInMonths: Int?
    ) async throws -> Domain.WinBackOffer {
        let timeRange: AppStoreConnect_Swift_SDK.IntegerRange? = {
            guard let timeSinceLastSubscribedMin, let timeSinceLastSubscribedMax else { return nil }
            return AppStoreConnect_Swift_SDK.IntegerRange(
                minimum: timeSinceLastSubscribedMin,
                maximum: timeSinceLastSubscribedMax
            )
        }()
        let sdkPriority = priority.map { AppStoreConnect_Swift_SDK.WinBackOfferUpdateRequest.Data.Attributes.Priority(rawValue: $0.rawValue) ?? .normal }
        let sdkPromo = promotionIntent.map { AppStoreConnect_Swift_SDK.WinBackOfferUpdateRequest.Data.Attributes.PromotionIntent(rawValue: $0.rawValue) ?? .notPromoted }

        let body = WinBackOfferUpdateRequest(data: .init(
            type: .winBackOffers,
            id: offerId,
            attributes: .init(
                customerEligibilityPaidSubscriptionDurationInMonths: paidSubscriptionDurationInMonths,
                customerEligibilityTimeSinceLastSubscribedInMonths: timeRange,
                customerEligibilityWaitBetweenOffersInMonths: waitBetweenOffersInMonths,
                startDate: startDate,
                endDate: endDate,
                priority: sdkPriority,
                promotionIntent: sdkPromo
            )
        ))
        let response = try await client.request(APIEndpoint.v1.winBackOffers.id(offerId).patch(body))
        // PATCH response does not include parent subscriptionId — preserve as empty.
        return mapOffer(response.data, subscriptionId: "")
    }

    public func deleteWinBackOffer(offerId: String) async throws {
        _ = try await client.request(APIEndpoint.v1.winBackOffers.id(offerId).delete)
    }

    public func listPrices(offerId: String) async throws -> [Domain.WinBackOfferPrice] {
        let request = APIEndpoint.v1.winBackOffers.id(offerId).prices.get()
        let response = try await client.request(request)
        return response.data.map { mapPrice($0, offerId: offerId) }
    }

    private func mapOffer(
        _ sdk: AppStoreConnect_Swift_SDK.WinBackOffer,
        subscriptionId: String
    ) -> Domain.WinBackOffer {
        let durationRaw = sdk.attributes?.duration?.rawValue ?? Domain.SubscriptionOfferDuration.oneMonth.rawValue
        let duration = Domain.SubscriptionOfferDuration(rawValue: durationRaw) ?? .oneMonth
        let modeRaw = sdk.attributes?.offerMode?.rawValue ?? Domain.SubscriptionOfferMode.payAsYouGo.rawValue
        let mode = Domain.SubscriptionOfferMode(rawValue: modeRaw) ?? .payAsYouGo
        let priorityRaw = sdk.attributes?.priority?.rawValue ?? Domain.WinBackOfferPriority.normal.rawValue
        let priority = Domain.WinBackOfferPriority(rawValue: priorityRaw) ?? .normal
        let promo = sdk.attributes?.promotionIntent.flatMap { Domain.WinBackOfferPromotionIntent(rawValue: $0.rawValue) }

        return Domain.WinBackOffer(
            id: sdk.id,
            subscriptionId: subscriptionId,
            referenceName: sdk.attributes?.referenceName ?? "",
            offerId: sdk.attributes?.offerID ?? "",
            duration: duration,
            offerMode: mode,
            periodCount: sdk.attributes?.periodCount ?? 1,
            customerEligibilityPaidSubscriptionDurationInMonths: sdk.attributes?.customerEligibilityPaidSubscriptionDurationInMonths ?? 0,
            customerEligibilityTimeSinceLastSubscribedMin: sdk.attributes?.customerEligibilityTimeSinceLastSubscribedInMonths?.minimum ?? 0,
            customerEligibilityTimeSinceLastSubscribedMax: sdk.attributes?.customerEligibilityTimeSinceLastSubscribedInMonths?.maximum ?? 0,
            customerEligibilityWaitBetweenOffersInMonths: sdk.attributes?.customerEligibilityWaitBetweenOffersInMonths,
            startDate: sdk.attributes?.startDate ?? "",
            endDate: sdk.attributes?.endDate,
            priority: priority,
            promotionIntent: promo
        )
    }

    private func mapPrice(
        _ sdk: AppStoreConnect_Swift_SDK.WinBackOfferPrice,
        offerId: String
    ) -> Domain.WinBackOfferPrice {
        Domain.WinBackOfferPrice(
            id: sdk.id,
            offerId: offerId,
            territory: sdk.relationships?.territory?.data?.id,
            subscriptionPricePointId: sdk.relationships?.subscriptionPricePoint?.data?.id
        )
    }
}

/// Minimal type-erased Encodable used to construct nested JSON payloads
/// where the generated SDK's request types are missing fields we need.
private enum AnyCodable: Encodable {
    case string(String)
    case int(Int)
    case bool(Bool)
    case array([AnyCodable])
    case object([String: AnyCodable])
    case null

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .int(let i): try container.encode(i)
        case .bool(let b): try container.encode(b)
        case .array(let a): try container.encode(a)
        case .object(let o): try container.encode(o)
        case .null: try container.encodeNil()
        }
    }
}
