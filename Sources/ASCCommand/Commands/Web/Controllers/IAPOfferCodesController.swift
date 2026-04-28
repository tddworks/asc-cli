import Domain
import Foundation
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return `InAppPurchaseOfferCode` resources.
struct IAPOfferCodesController: Sendable {
    let repo: any InAppPurchaseOfferCodeRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/iap/:iapId/offer-codes") { _, context -> Response in
            guard let iapId = context.parameters.get("iapId") else { return jsonError("Missing iapId") }
            let items = try await self.repo.listOfferCodes(iapId: iapId)
            return try restFormat(items)
        }

        group.post("/iap/:iapId/offer-codes") { request, context -> Response in
            guard let iapId = context.parameters.get("iapId") else { return jsonError("Missing iapId") }
            let body = try await request.body.collect(upTo: 64 * 1024)
            let json = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            guard let name = json["name"] as? String, !name.isEmpty else {
                return jsonError("Missing name", status: .badRequest)
            }
            // Body accepts `customerEligibilities: ["NON_SPENDER", ...]` or `eligibility` shorthand.
            let rawEligibilities = (json["customerEligibilities"] as? [String])
                ?? (json["eligibility"] as? [String])
                ?? []
            let eligibilities = rawEligibilities.compactMap { IAPCustomerEligibility(rawValue: $0) }
            guard !eligibilities.isEmpty else {
                return jsonError(
                    "Missing customerEligibilities — pick one or more of NON_SPENDER, ACTIVE_SPENDER, CHURNED_SPENDER",
                    status: .badRequest
                )
            }
            do {
                let created = try await self.repo.createOfferCode(
                    iapId: iapId,
                    name: name,
                    customerEligibilities: eligibilities
                )
                return try restFormat(created)
            } catch {
                return jsonError(error.localizedDescription, status: .badRequest)
            }
        }
    }
}
