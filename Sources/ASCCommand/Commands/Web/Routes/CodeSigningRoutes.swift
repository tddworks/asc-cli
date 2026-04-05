import Hummingbird
import HummingbirdWebSocket
import ASCPlugin
import Infrastructure
import Domain

/// /api/v1/certificates, bundle-ids, devices, profiles — Code signing routes.
enum CodeSigningRoutes {
    static func register(on group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/certificates") { _, _ -> Response in
            try await restExec { try await CertificatesList.parse(["--pretty"]).execute(repo: ClientProvider.makeCertificateRepository(), affordanceMode: .rest) }
        }

        group.get("/bundle-ids") { _, _ -> Response in
            try await restExec { try await BundleIDsList.parse(["--pretty"]).execute(repo: ClientProvider.makeBundleIDRepository(), affordanceMode: .rest) }
        }

        group.get("/devices") { _, _ -> Response in
            try await restExec { try await DevicesList.parse(["--pretty"]).execute(repo: ClientProvider.makeDeviceRepository(), affordanceMode: .rest) }
        }

        group.get("/profiles") { _, _ -> Response in
            try await restExec { try await ProfilesList.parse(["--pretty"]).execute(repo: ClientProvider.makeProfileRepository(), affordanceMode: .rest) }
        }
    }
}
