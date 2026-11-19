import ArgumentParser
import ASCKit
import Foundation
import Hummingbird
import HummingbirdWebSocket

/// `GET  /api/v1/iris/apps/:appId/compliance-requirements` — the app's App Compliance page.
/// `POST /api/v1/iris/apps/:appId/compliance-requirements/:requirementId/declare` with
/// `{"answer": "yes" | "no"}` — answers one. Iris private API only (browser-cookie auth).
struct IrisAppComplianceController: Sendable {
    let cookieProvider: any IrisCookieProvider
    let repo: any IrisComplianceRepository

    private struct DeclareBody: Decodable {
        let answer: String
    }

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/iris/apps/:appId/compliance-requirements") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            let session = try self.cookieProvider.resolveSession()
            return try await self.answering { try restFormat(try await self.repo.listRequirements(session: session, appId: appId)) }
        }

        group.post("/iris/apps/:appId/compliance-requirements/:requirementId/declare") { request, context -> Response in
            guard let appId = context.parameters.get("appId"),
                  let requirementId = context.parameters.get("requirementId") else { return jsonError("Missing appId or requirementId") }
            let body = try? await request.decode(as: DeclareBody.self, context: context)
            guard let answer = body.flatMap({ DeclaredAnswerArgument(rawValue: $0.answer.lowercased()) }) else {
                return jsonError(#"answer must be "yes" or "no""#)
            }
            let session = try self.cookieProvider.resolveSession()
            return try await self.answering {
                let requirement = try await self.repo.requirement(requirementId, appId: appId, session: session)
                return try restFormat(try await requirement.declare(try answer.answer(), session: session, repo: self.repo))
            }
        }
    }

    /// A refusal the domain explains is answered with its own words and status.
    private func answering(_ handler: () async throws -> Response) async throws -> Response {
        do {
            return try await handler()
        } catch let error as ComplianceError {
            switch error {
            case .requirementNotFound: return jsonError(error.description, status: .notFound)
            case .roleCannotEdit: return jsonError(error.description, status: .forbidden)
            case .teamUnknown: return jsonError(error.description, status: .unauthorized)
            case .notDeclarable, .readOnly: return jsonError(error.description, status: .conflict)
            }
        } catch let error as ValidationError {
            return jsonError(error.message, status: .unprocessableContent)
        }
    }
}
