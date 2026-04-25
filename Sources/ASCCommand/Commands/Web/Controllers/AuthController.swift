import Domain
import Foundation
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that manage saved App Store Connect API key credentials.
///
/// Mirrors the `asc auth` CLI tree:
///   POST   /auth/accounts            ↔ asc auth login
///   GET    /auth/accounts            ↔ asc auth list
///   GET    /auth/accounts/active     ↔ asc auth check
///   PATCH  /auth/accounts/active     ↔ asc auth use NAME       (body: { name })
///   PATCH  /auth/accounts/:name      ↔ asc auth update         (body: { vendorNumber })
///   DELETE /auth/accounts/active     ↔ asc auth logout
///   DELETE /auth/accounts/:name      ↔ asc auth logout --name X
///
/// Security note: this controller writes API key PEMs to disk via `AuthStorage`.
/// Run the web server bound to loopback only.
struct AuthController: Sendable {
    let storage: any AuthStorage

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/auth/accounts") { _, _ -> Response in
            let accounts = try self.storage.loadAll()
            return try restFormat(accounts)
        }

        group.post("/auth/accounts") { request, _ -> Response in
            let body = try await request.body.collect(upTo: 256 * 1024)
            let json = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            guard let keyID = json["keyId"] as? String, !keyID.isEmpty else {
                return jsonError("Missing keyId", status: .badRequest)
            }
            guard let issuerID = json["issuerId"] as? String, !issuerID.isEmpty else {
                return jsonError("Missing issuerId", status: .badRequest)
            }
            guard let pem = json["privateKeyPEM"] as? String, !pem.isEmpty else {
                return jsonError("Missing privateKeyPEM", status: .badRequest)
            }
            let name = (json["name"] as? String) ?? "default"
            if name.contains(where: \.isWhitespace) {
                return jsonError("Account name must not contain spaces", status: .badRequest)
            }
            let credentials = AuthCredentials(
                keyID: keyID,
                issuerID: issuerID,
                privateKeyPEM: pem,
                vendorNumber: json["vendorNumber"] as? String
            )
            do { try credentials.validate() }
            catch { return jsonError(error.localizedDescription, status: .badRequest) }

            try self.storage.save(credentials, name: name)
            try self.storage.setActive(name: name)
            let status = AuthStatus(
                name: name,
                keyID: keyID,
                issuerID: issuerID,
                source: .file,
                vendorNumber: credentials.vendorNumber
            )
            return try restFormat(status)
        }

        group.get("/auth/accounts/active") { _, _ -> Response in
            let accounts = try self.storage.loadAll()
            guard let active = accounts.first(where: \.isActive) else {
                return jsonError("No active account", status: .notFound)
            }
            let status = AuthStatus(
                name: active.name,
                keyID: active.keyID,
                issuerID: active.issuerID,
                source: .file,
                vendorNumber: active.vendorNumber
            )
            return try restFormat(status)
        }

        group.patch("/auth/accounts/active") { request, _ -> Response in
            let body = try await request.body.collect(upTo: 64 * 1024)
            let json = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            guard let name = json["name"] as? String, !name.isEmpty else {
                return jsonError("Missing name", status: .badRequest)
            }
            try self.storage.setActive(name: name)
            guard let creds = try self.storage.load(name: name) else {
                return jsonError("Account not found: \(name)", status: .notFound)
            }
            let status = AuthStatus(
                name: name,
                keyID: creds.keyID,
                issuerID: creds.issuerID,
                source: .file,
                vendorNumber: creds.vendorNumber
            )
            return try restFormat(status)
        }

        group.patch("/auth/accounts/:name") { request, context -> Response in
            guard let name = context.parameters.get("name") else { return jsonError("Missing name") }
            let body = try await request.body.collect(upTo: 64 * 1024)
            let json = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            guard let existing = try self.storage.load(name: name) else {
                return jsonError("Account not found: \(name)", status: .notFound)
            }
            let updated = AuthCredentials(
                keyID: existing.keyID,
                issuerID: existing.issuerID,
                privateKeyPEM: existing.privateKeyPEM,
                vendorNumber: (json["vendorNumber"] as? String) ?? existing.vendorNumber
            )
            try self.storage.save(updated, name: name)
            let status = AuthStatus(
                name: name,
                keyID: updated.keyID,
                issuerID: updated.issuerID,
                source: .file,
                vendorNumber: updated.vendorNumber
            )
            return try restFormat(status)
        }

        group.delete("/auth/accounts/active") { _, _ -> Response in
            try self.storage.delete(name: nil)
            return Response(status: .noContent)
        }

        group.delete("/auth/accounts/:name") { _, context -> Response in
            guard let name = context.parameters.get("name") else { return jsonError("Missing name") }
            try self.storage.delete(name: name)
            return Response(status: .noContent)
        }
    }
}
