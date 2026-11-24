import ASCKit
import Foundation
import Hummingbird
import HummingbirdWebSocket

/// `GET  /api/v1/iris/apps/:appId/app-privacy` — the app's privacy label.
/// `POST /api/v1/iris/apps/:appId/app-privacy/declare` with `{"notCollected": true}` or
/// `{"collectedData": [...]}` — replaces it (a draft until published).
/// `POST /api/v1/iris/apps/:appId/app-privacy/publish` — makes it live.
/// Iris private API only (browser-cookie auth).
struct IrisAppPrivacyController: Sendable {
    let cookieProvider: any IrisCookieProvider
    let repo: any IrisAppPrivacyRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/iris/apps/:appId/app-privacy") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let session = try self.cookieProvider.resolveSession()
            return try restFormat(try await self.repo.fetchPrivacy(session: session, appId: appId))
        }

        group.post("/iris/apps/:appId/app-privacy/declare") { request, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let bytes = try await request.body.collect(upTo: 1_000_000)
            guard let declaration = try? JSONDecoder().decode(PrivacyDeclaration.self, from: Data(buffer: bytes)) else {
                return jsonError(#"Send either {"notCollected": true} or {"collectedData": [...]}"#)
            }
            let session = try self.cookieProvider.resolveSession()
            return try await self.answering {
                let privacy = try await self.repo.fetchPrivacy(session: session, appId: appId)
                return try restFormat(try await privacy.declare(declaration, session: session, repo: self.repo))
            }
        }

        group.post("/iris/apps/:appId/app-privacy/publish") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let session = try self.cookieProvider.resolveSession()
            return try await self.answering {
                let privacy = try await self.repo.fetchPrivacy(session: session, appId: appId)
                return try restFormat(try await privacy.publish(session: session, repo: self.repo))
            }
        }
    }

    /// A refusal the domain explains is answered with its own words and status.
    private func answering(_ handler: () async throws -> Response) async throws -> Response {
        do {
            return try await handler()
        } catch let error as AppPrivacyError {
            switch error {
            case .nothingDeclared: return jsonError(error.description, status: .conflict)
            case .noDataTypes, .noPurposes, .unknownCategory, .unknownPurpose, .duplicateCategory:
                return jsonError(error.description, status: .unprocessableContent)
            }
        }
    }
}
