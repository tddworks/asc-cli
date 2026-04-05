import Hummingbird
import HummingbirdWebSocket
import ASCPlugin
import Infrastructure
import Domain

/// /api/v1/certificates, bundle-ids, devices, profiles — Code signing routes.
enum CodeSigningRoutes {
    static func register(on group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/certificates") { _, _ -> Response in
            let certs = try await ClientProvider.makeCertificateRepository().listCertificates(certificateType: nil)
            return try restFormat(certs)
        }

        group.get("/bundle-ids") { _, _ -> Response in
            let ids = try await ClientProvider.makeBundleIDRepository().listBundleIDs(platform: nil, identifier: nil)
            return try restFormat(ids)
        }

        group.get("/devices") { _, _ -> Response in
            let devices = try await ClientProvider.makeDeviceRepository().listDevices(platform: nil)
            return try restFormat(devices)
        }

        group.get("/profiles") { _, _ -> Response in
            let profiles = try await ClientProvider.makeProfileRepository().listProfiles(bundleIdId: nil, profileType: nil)
            return try restFormat(profiles)
        }
    }
}
