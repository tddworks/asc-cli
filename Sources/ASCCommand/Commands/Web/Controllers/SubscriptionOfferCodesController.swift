import Domain
import Foundation
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return `SubscriptionOfferCode` resources.
struct SubscriptionOfferCodesController: Sendable {
    let repo: any SubscriptionOfferCodeRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/subscriptions/:subscriptionId/offer-codes") { _, context -> Response in
            guard let subscriptionId = context.parameters.get("subscriptionId") else { return jsonError("Missing subscriptionId") }
            let items = try await self.repo.listOfferCodes(subscriptionId: subscriptionId)
            return try restFormat(items)
        }

        group.post("/subscriptions/:subscriptionId/offer-codes") { request, context -> Response in
            guard let subscriptionId = context.parameters.get("subscriptionId") else { return jsonError("Missing subscriptionId") }
            let body = try await request.body.collect(upTo: 64 * 1024)
            let json = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            guard let name = json["name"] as? String, !name.isEmpty else {
                return jsonError("Missing name", status: .badRequest)
            }
            guard let durationRaw = json["duration"] as? String,
                  let duration = SubscriptionOfferDuration(rawValue: durationRaw) else {
                return jsonError(
                    "Missing or invalid duration — use ONE_MONTH, THREE_MONTHS, SIX_MONTHS, ONE_YEAR, etc.",
                    status: .badRequest
                )
            }
            guard let modeRaw = (json["mode"] as? String) ?? (json["offerMode"] as? String),
                  let offerMode = SubscriptionOfferMode(rawValue: modeRaw) else {
                return jsonError(
                    "Missing or invalid mode — use FREE_TRIAL, PAY_AS_YOU_GO, or PAY_UP_FRONT",
                    status: .badRequest
                )
            }
            guard let numberOfPeriods = (json["periods"] as? Int) ?? (json["numberOfPeriods"] as? Int) else {
                return jsonError("Missing periods (Int)", status: .badRequest)
            }
            let rawEligibilities = (json["customerEligibilities"] as? [String])
                ?? (json["eligibility"] as? [String])
                ?? []
            let eligibilities = rawEligibilities.compactMap { SubscriptionCustomerEligibility(rawValue: $0) }
            guard !eligibilities.isEmpty else {
                return jsonError(
                    "Missing customerEligibilities — pick one or more of NEW, LAPSED, WIN_BACK, PAID_SUBSCRIBER",
                    status: .badRequest
                )
            }
            guard let offerEligRaw = (json["offerEligibility"] as? String) ?? (json["offer-eligibility"] as? String),
                  let offerEligibility = SubscriptionOfferEligibility(rawValue: offerEligRaw) else {
                return jsonError(
                    "Missing or invalid offerEligibility — use STACKABLE, INTRODUCTORY, or SUBSCRIPTION_OFFER",
                    status: .badRequest
                )
            }
            // `isAutoRenewEnabled` defaults to `true` when omitted (ASC's normal renewing offer).
            let isAutoRenewEnabled = (json["isAutoRenewEnabled"] as? Bool)
                ?? (json["autoRenew"] as? Bool)
                ?? (json["auto-renew"] as? Bool)
                ?? true
            // Same `prices` body shape as IAP — `pricePointId` nil/absent → free territory.
            let prices: [OfferCodePriceInput] = (json["prices"] as? [[String: Any]] ?? []).compactMap { entry in
                guard let territory = entry["territory"] as? String, !territory.isEmpty else { return nil }
                let pricePointId = entry["pricePointId"] as? String
                return OfferCodePriceInput(territory: territory, pricePointId: pricePointId)
            }
            do {
                let created = try await self.repo.createOfferCode(
                    subscriptionId: subscriptionId,
                    name: name,
                    customerEligibilities: eligibilities,
                    offerEligibility: offerEligibility,
                    duration: duration,
                    offerMode: offerMode,
                    numberOfPeriods: numberOfPeriods,
                    isAutoRenewEnabled: isAutoRenewEnabled,
                    prices: prices
                )
                return try restFormat(created)
            } catch {
                return jsonError(error.localizedDescription, status: .badRequest)
            }
        }
    }
}
