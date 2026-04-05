import Hummingbird
import HummingbirdWebSocket
import ASCPlugin
import Domain

/// /api/v1/certificates, bundle-ids, devices, profiles — Code signing routes.
struct CodeSigningController: Sendable {
    let certRepo: any CertificateRepository
    let bundleIDRepo: any BundleIDRepository
    let deviceRepo: any DeviceRepository
    let profileRepo: any ProfileRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/certificates") { _, _ -> Response in
            let certs = try await self.certRepo.listCertificates(certificateType: nil)
            return try restFormat(certs)
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
