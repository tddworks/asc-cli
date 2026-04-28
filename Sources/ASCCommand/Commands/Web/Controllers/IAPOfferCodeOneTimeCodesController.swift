import Domain
import Foundation
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return `InAppPurchaseOfferCodeOneTimeUseCode` resources.
///
/// Mirrors `asc iap-offer-code-one-time-codes list/create/update` so REST clients can
/// generate sandbox or production redemption batches and toggle individual batches active.
struct IAPOfferCodeOneTimeCodesController: Sendable {
    let repo: any InAppPurchaseOfferCodeRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/iap-offer-codes/:offerCodeId/one-time-codes") { _, context -> Response in
            guard let offerCodeId = context.parameters.get("offerCodeId") else {
                return jsonError("Missing offerCodeId")
            }
            do {
                let items = try await self.repo.listOneTimeUseCodes(offerCodeId: offerCodeId)
                return try restFormat(items)
            } catch {
                return jsonError(error.localizedDescription, status: .badRequest)
            }
        }

        group.post("/iap-offer-codes/:offerCodeId/one-time-codes") { request, context -> Response in
            guard let offerCodeId = context.parameters.get("offerCodeId") else {
                return jsonError("Missing offerCodeId")
            }
            let body = try await request.body.collect(upTo: 64 * 1024)
            let json = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            guard let numberOfCodes = json["numberOfCodes"] as? Int else {
                return jsonError("Missing numberOfCodes", status: .badRequest)
            }
            guard let expirationDate = json["expirationDate"] as? String else {
                return jsonError("Missing expirationDate", status: .badRequest)
            }
            // Body field "environment" accepts "production" or "sandbox" (lowercase) or
            // "PRODUCTION"/"SANDBOX" (raw enum). Defaults to production to match the CLI.
            let environment = (json["environment"] as? String).flatMap {
                OfferCodeEnvironment(rawValue: $0.uppercased())
            } ?? .production
            do {
                let created = try await self.repo.createOneTimeUseCode(
                    offerCodeId: offerCodeId,
                    numberOfCodes: numberOfCodes,
                    expirationDate: expirationDate,
                    environment: environment
                )
                return try restFormat(created)
            } catch {
                return jsonError(error.localizedDescription, status: .badRequest)
            }
        }

        group.patch("/iap-offer-code-one-time-codes/:oneTimeCodeId") { request, context -> Response in
            guard let oneTimeCodeId = context.parameters.get("oneTimeCodeId") else {
                return jsonError("Missing oneTimeCodeId")
            }
            let body = try await request.body.collect(upTo: 64 * 1024)
            let json = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            guard let isActive = json["isActive"] as? Bool ?? json["active"] as? Bool else {
                return jsonError("Missing isActive", status: .badRequest)
            }
            do {
                let updated = try await self.repo.updateOneTimeUseCode(
                    oneTimeCodeId: oneTimeCodeId,
                    isActive: isActive
                )
                return try restFormat(updated)
            } catch {
                return jsonError(error.localizedDescription, status: .badRequest)
            }
        }
    }
}
