import Foundation
import Hummingbird
import HummingbirdWebSocket
import ASCPlugin
import Domain
import Infrastructure

/// /api/v1/certificates, bundle-ids, devices, profiles — Code signing routes.
struct CodeSigningController: Sendable {
    let certRepo: any CertificateRepository
    let bundleIDRepo: any BundleIDRepository
    let deviceRepo: any DeviceRepository
    let profileRepo: any ProfileRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/certificates") { request, _ -> Response in
            let query = request.uri.queryParameters
            let certType = query["type"].flatMap { CertificateType(rawValue: String($0).uppercased()) }
            let limit = query["limit"].flatMap { Int($0) }
            let expiredOnly = ["true", "1", "yes"].contains(String(query["expired-only"] ?? "").lowercased())

            var items = try await self.certRepo.listCertificates(certificateType: certType, limit: limit)
            if expiredOnly {
                items = items.filter(\.isExpired)
            }
            if let beforeRaw = query["before"] {
                guard let cutoff = ISO8601DateFormatter().date(from: String(beforeRaw)) else {
                    return jsonError("'before' must be an ISO8601 date (e.g. 2026-11-01T00:00:00Z)")
                }
                items = items.filter { cert in
                    guard let exp = cert.expirationDate else { return false }
                    return exp < cutoff
                }
            }
            return try restFormat(items)
        }

        group.get("/bundle-ids") { _, _ -> Response in
            let ids = try await self.bundleIDRepo.listBundleIDs(platform: nil, identifier: nil)
            return try restFormat(ids)
        }

        group.get("/devices") { _, _ -> Response in
            let devices = try await self.deviceRepo.listDevices(platform: nil)
            return try restFormat(devices)
        }

        group.get("/profiles") { _, _ -> Response in
            let profiles = try await self.profileRepo.listProfiles(bundleIdId: nil, profileType: nil)
            return try restFormat(profiles)
        }
    }
}
