import Foundation
@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKSubscriptionOfferCodeRepository: SubscriptionOfferCodeRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    // MARK: - Offer Codes

    public func listOfferCodes(subscriptionId: String) async throws -> [Domain.SubscriptionOfferCode] {
        let request = APIEndpoint.v1.subscriptions.id(subscriptionId).offerCodes.get()
        let response = try await client.request(request)
        return response.data.map { mapOfferCode($0, subscriptionId: subscriptionId) }
    }

    public func createOfferCode(
        subscriptionId: String,
        name: String,
        customerEligibilities: [Domain.SubscriptionCustomerEligibility],
        offerEligibility: Domain.SubscriptionOfferEligibility,
        duration: Domain.SubscriptionOfferDuration,
        offerMode: Domain.SubscriptionOfferMode,
        numberOfPeriods: Int
    ) async throws -> Domain.SubscriptionOfferCode {
        let sdkEligibilities = customerEligibilities.compactMap {
            AppStoreConnect_Swift_SDK.SubscriptionCustomerEligibility(rawValue: mapCustomerEligibilityToSDK($0))
        }
        let sdkOfferEligibility = AppStoreConnect_Swift_SDK.SubscriptionOfferEligibility(rawValue: mapOfferEligibilityToSDK(offerEligibility))
            ?? .stackWithIntroOffers
        let sdkDuration = AppStoreConnect_Swift_SDK.SubscriptionOfferDuration(rawValue: duration.rawValue) ?? .oneMonth
        let sdkMode = AppStoreConnect_Swift_SDK.SubscriptionOfferMode(rawValue: offerMode.rawValue) ?? .freeTrial

        let body = SubscriptionOfferCodeCreateRequest(
            data: .init(
                type: .subscriptionOfferCodes,
                attributes: .init(
                    name: name,
                    customerEligibilities: sdkEligibilities,
                    offerEligibility: sdkOfferEligibility,
                    duration: sdkDuration,
                    offerMode: sdkMode,
                    numberOfPeriods: numberOfPeriods
                ),
                relationships: .init(
                    subscription: .init(data: .init(type: .subscriptions, id: subscriptionId)),
                    prices: .init(data: [])
                )
            )
        )
        let response = try await client.request(APIEndpoint.v1.subscriptionOfferCodes.post(body))
        return mapOfferCode(response.data, subscriptionId: subscriptionId)
    }

    public func updateOfferCode(offerCodeId: String, isActive: Bool) async throws -> Domain.SubscriptionOfferCode {
        let body = SubscriptionOfferCodeUpdateRequest(
            data: .init(
                type: .subscriptionOfferCodes,
                id: offerCodeId,
                attributes: .init(isActive: isActive)
            )
        )
        let response = try await client.request(APIEndpoint.v1.subscriptionOfferCodes.id(offerCodeId).patch(body))
        return mapOfferCode(response.data, subscriptionId: "")
    }

    // MARK: - Custom Codes

    public func listCustomCodes(offerCodeId: String) async throws -> [Domain.SubscriptionOfferCodeCustomCode] {
        let request = APIEndpoint.v1.subscriptionOfferCodes.id(offerCodeId).customCodes.get()
        let response = try await client.request(request)
        return response.data.map { mapCustomCode($0, offerCodeId: offerCodeId) }
    }

    public func createCustomCode(
        offerCodeId: String,
        customCode: String,
        numberOfCodes: Int,
        expirationDate: String?
    ) async throws -> Domain.SubscriptionOfferCodeCustomCode {
        let body = SubscriptionOfferCodeCustomCodeCreateRequest(
            data: .init(
                type: .subscriptionOfferCodeCustomCodes,
                attributes: .init(
                    customCode: customCode,
                    numberOfCodes: numberOfCodes,
                    expirationDate: expirationDate
                ),
                relationships: .init(
                    offerCode: .init(data: .init(type: .subscriptionOfferCodes, id: offerCodeId))
                )
            )
        )
        let response = try await client.request(APIEndpoint.v1.subscriptionOfferCodeCustomCodes.post(body))
        return mapCustomCode(response.data, offerCodeId: offerCodeId)
    }

    public func updateCustomCode(customCodeId: String, isActive: Bool) async throws -> Domain.SubscriptionOfferCodeCustomCode {
        let body = SubscriptionOfferCodeCustomCodeUpdateRequest(
            data: .init(
                type: .subscriptionOfferCodeCustomCodes,
                id: customCodeId,
                attributes: .init(isActive: isActive)
            )
        )
        let response = try await client.request(APIEndpoint.v1.subscriptionOfferCodeCustomCodes.id(customCodeId).patch(body))
        return mapCustomCode(response.data, offerCodeId: "")
    }

    // MARK: - One-Time Use Codes

    public func listOneTimeUseCodes(offerCodeId: String) async throws -> [Domain.SubscriptionOfferCodeOneTimeUseCode] {
        let request = APIEndpoint.v1.subscriptionOfferCodes.id(offerCodeId).oneTimeUseCodes.get()
        let response = try await client.request(request)
        return response.data.map { mapOneTimeUseCode($0, offerCodeId: offerCodeId) }
    }

    public func createOneTimeUseCode(
        offerCodeId: String,
        numberOfCodes: Int,
        expirationDate: String
    ) async throws -> Domain.SubscriptionOfferCodeOneTimeUseCode {
        let body = SubscriptionOfferCodeOneTimeUseCodeCreateRequest(
            data: .init(
                type: .subscriptionOfferCodeOneTimeUseCodes,
                attributes: .init(
                    numberOfCodes: numberOfCodes,
                    expirationDate: expirationDate
                ),
                relationships: .init(
                    offerCode: .init(data: .init(type: .subscriptionOfferCodes, id: offerCodeId))
                )
            )
        )
        let response = try await client.request(APIEndpoint.v1.subscriptionOfferCodeOneTimeUseCodes.post(body))
        return mapOneTimeUseCode(response.data, offerCodeId: offerCodeId)
    }

    public func updateOneTimeUseCode(oneTimeCodeId: String, isActive: Bool) async throws -> Domain.SubscriptionOfferCodeOneTimeUseCode {
        let body = SubscriptionOfferCodeOneTimeUseCodeUpdateRequest(
            data: .init(
                type: .subscriptionOfferCodeOneTimeUseCodes,
                id: oneTimeCodeId,
                attributes: .init(isActive: isActive)
            )
        )
        let response = try await client.request(APIEndpoint.v1.subscriptionOfferCodeOneTimeUseCodes.id(oneTimeCodeId).patch(body))
        return mapOneTimeUseCode(response.data, offerCodeId: "")
    }

    public func fetchOneTimeUseCodeValues(oneTimeCodeId: String) async throws -> String {
        let request = APIEndpoint.v1.subscriptionOfferCodeOneTimeUseCodes.id(oneTimeCodeId).values.get
        return try await client.request(request)
    }

    // MARK: - Prices

    public func listPrices(offerCodeId: String) async throws -> [Domain.SubscriptionOfferCodePrice] {
        let request = APIEndpoint.v1.subscriptionOfferCodes.id(offerCodeId).prices.get()
        let response = try await client.request(request)
        return response.data.map { mapPrice($0, offerCodeId: offerCodeId) }
    }

    private func mapPrice(
        _ sdk: AppStoreConnect_Swift_SDK.SubscriptionOfferCodePrice,
        offerCodeId: String
    ) -> Domain.SubscriptionOfferCodePrice {
        Domain.SubscriptionOfferCodePrice(
            id: sdk.id,
            offerCodeId: offerCodeId,
            territory: sdk.relationships?.territory?.data?.id,
            subscriptionPricePointId: sdk.relationships?.subscriptionPricePoint?.data?.id
        )
    }

    // MARK: - Mappers

    private func mapOfferCode(
        _ sdk: AppStoreConnect_Swift_SDK.SubscriptionOfferCode,
        subscriptionId: String
    ) -> Domain.SubscriptionOfferCode {
        let customerEligibilities = (sdk.attributes?.customerEligibilities ?? []).compactMap { sdkEligibility -> Domain.SubscriptionCustomerEligibility? in
            mapCustomerEligibilityToDomain(sdkEligibility)
        }
        let offerEligibility = sdk.attributes?.offerEligibility.flatMap { mapOfferEligibilityToDomain($0) } ?? .stackable
        let durationRaw = sdk.attributes?.duration?.rawValue ?? Domain.SubscriptionOfferDuration.oneMonth.rawValue
        let duration = Domain.SubscriptionOfferDuration(rawValue: durationRaw) ?? .oneMonth
        let modeRaw = sdk.attributes?.offerMode?.rawValue ?? Domain.SubscriptionOfferMode.freeTrial.rawValue
        let offerMode = Domain.SubscriptionOfferMode(rawValue: modeRaw) ?? .freeTrial

        return Domain.SubscriptionOfferCode(
            id: sdk.id,
            subscriptionId: subscriptionId,
            name: sdk.attributes?.name ?? "",
            customerEligibilities: customerEligibilities,
            offerEligibility: offerEligibility,
            duration: duration,
            offerMode: offerMode,
            numberOfPeriods: sdk.attributes?.numberOfPeriods ?? 1,
            totalNumberOfCodes: sdk.attributes?.totalNumberOfCodes,
            isActive: sdk.attributes?.isActive ?? false
        )
    }

    private func mapCustomCode(
        _ sdk: AppStoreConnect_Swift_SDK.SubscriptionOfferCodeCustomCode,
        offerCodeId: String
    ) -> Domain.SubscriptionOfferCodeCustomCode {
        let createdDateString: String? = sdk.attributes?.createdDate.map { ISO8601DateFormatter().string(from: $0) }

        return Domain.SubscriptionOfferCodeCustomCode(
            id: sdk.id,
            offerCodeId: offerCodeId,
            customCode: sdk.attributes?.customCode ?? "",
            numberOfCodes: sdk.attributes?.numberOfCodes ?? 0,
            createdDate: createdDateString,
            expirationDate: sdk.attributes?.expirationDate,
            isActive: sdk.attributes?.isActive ?? false
        )
    }

    private func mapOneTimeUseCode(
        _ sdk: AppStoreConnect_Swift_SDK.SubscriptionOfferCodeOneTimeUseCode,
        offerCodeId: String
    ) -> Domain.SubscriptionOfferCodeOneTimeUseCode {
        let createdDateString: String? = sdk.attributes?.createdDate.map { ISO8601DateFormatter().string(from: $0) }

        return Domain.SubscriptionOfferCodeOneTimeUseCode(
            id: sdk.id,
            offerCodeId: offerCodeId,
            numberOfCodes: sdk.attributes?.numberOfCodes ?? 0,
            createdDate: createdDateString,
            expirationDate: sdk.attributes?.expirationDate,
            isActive: sdk.attributes?.isActive ?? false
        )
    }

    // MARK: - Eligibility Mapping

    /// Maps domain customer eligibility to SDK raw value
    /// Domain: NEW, LAPSED, WIN_BACK, PAID_SUBSCRIBER
    /// SDK:    NEW, EXISTING, EXPIRED
    private func mapCustomerEligibilityToSDK(_ domain: Domain.SubscriptionCustomerEligibility) -> String {
        switch domain {
        case .new: return "NEW"
        case .lapsed: return "EXPIRED"
        case .winBack: return "EXPIRED"
        case .paidSubscriber: return "EXISTING"
        }
    }

    /// Maps SDK customer eligibility to domain
    private func mapCustomerEligibilityToDomain(_ sdk: AppStoreConnect_Swift_SDK.SubscriptionCustomerEligibility) -> Domain.SubscriptionCustomerEligibility? {
        switch sdk {
        case .new: return .new
        case .existing: return .paidSubscriber
        case .expired: return .lapsed
        }
    }

    /// Maps domain offer eligibility to SDK raw value
    /// Domain: STACKABLE, INTRODUCTORY, SUBSCRIPTION_OFFER
    /// SDK:    STACK_WITH_INTRO_OFFERS, REPLACE_INTRO_OFFERS
    private func mapOfferEligibilityToSDK(_ domain: Domain.SubscriptionOfferEligibility) -> String {
        switch domain {
        case .stackable: return "STACK_WITH_INTRO_OFFERS"
        case .introductory: return "REPLACE_INTRO_OFFERS"
        case .subscriptionOffer: return "STACK_WITH_INTRO_OFFERS"
        }
    }

    /// Maps SDK offer eligibility to domain
    private func mapOfferEligibilityToDomain(_ sdk: AppStoreConnect_Swift_SDK.SubscriptionOfferEligibility) -> Domain.SubscriptionOfferEligibility {
        switch sdk {
        case .stackWithIntroOffers: return .stackable
        case .replaceIntroOffers: return .introductory
        }
    }
}
