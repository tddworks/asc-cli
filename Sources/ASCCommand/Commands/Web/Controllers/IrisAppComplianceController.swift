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
        struct File: Decodable {
            let name: String
            /// The file's bytes, base64-encoded.
            let data: String
        }

        struct Evidence: Decodable {
            let proof: File?
            let report: File?
            let filingType: String?
            let filingName: String?
            let filingNumber: String?
            let thirdPartyAuthorization: File?
        }

        let answer: String
        let evidence: Evidence?

        func evidenceInput() -> ComplianceEvidenceInput {
            func file(_ file: File?) -> ComplianceFile? {
                file.flatMap { f in Data(base64Encoded: f.data).map { ComplianceFile(name: f.name, data: $0) } }
            }
            return ComplianceEvidenceInput(
                proof: file(evidence?.proof), report: file(evidence?.report),
                filingType: evidence?.filingType.flatMap(AIGCFiling.FilingType.init(rawValue:)),
                filingName: evidence?.filingName, filingNumber: evidence?.filingNumber,
                thirdPartyAuthorization: file(evidence?.thirdPartyAuthorization)
            )
        }
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
            guard let body, let answer = DeclaredAnswerArgument(rawValue: body.answer.lowercased()) else {
                return jsonError(#"answer must be "yes" or "no""#)
            }
            let session = try self.cookieProvider.resolveSession()
            return try await self.answering {
                let requirement = try await self.repo.requirement(requirementId, appId: appId, session: session)
                let declared = try answer.answer(for: requirement.kind, evidence: body.evidenceInput())
                return try restFormat(try await requirement.declare(declared, session: session, repo: self.repo))
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
            case .evidenceMissing, .evidenceMismatch, .fileTypeNotAllowed: return jsonError(error.description, status: .unprocessableContent)
            case .formNotUnderstood: return jsonError(error.description, status: .conflict)
            }
        }
    }
}
