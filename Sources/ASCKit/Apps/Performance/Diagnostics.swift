import Mockable

@Mockable
public protocol Diagnostics: Sendable {
    func listSignatures(buildId: String, diagnosticType: DiagnosticType?) async throws -> [DiagnosticSignatureInfo]
    func listLogs(signatureId: String) async throws -> [DiagnosticLogEntry]
}
