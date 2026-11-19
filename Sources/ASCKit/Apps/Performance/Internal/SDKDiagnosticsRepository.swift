@preconcurrency import AppStoreConnect_Swift_SDK

public struct SDKDiagnosticsRepository: DiagnosticsRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listSignatures(buildId: String, diagnosticType: DiagnosticType?) async throws -> [DiagnosticSignatureInfo] {
        let filterType = diagnosticType.flatMap { mapDiagnosticTypeFilter($0) }.map { [$0] }
        let pages = try await client.requestAllPages(
            APIEndpoint.v1.builds.id(buildId).diagnosticSignatures.get(parameters: .init(
                filterDiagnosticType: filterType,
                limit: 200
            )),
            nextCursor: { $0.meta?.paging.nextCursor }
        )
        return pages.flatMap(\.data).map { mapSignature($0, buildId: buildId) }
    }

    public func listLogs(signatureId: String) async throws -> [DiagnosticLogEntry] {
        let request = APIEndpoint.v1.diagnosticSignatures.id(signatureId).logs.get()
        let response = try await client.request(request)
        return flattenLogs(response, signatureId: signatureId)
    }

    private func mapDiagnosticTypeFilter(
        _ type: DiagnosticType
    ) -> APIEndpoint.V1.Builds.WithID.DiagnosticSignatures.GetParameters.FilterDiagnosticType? {
        switch type {
        case .diskWrites: return .diskWrites
        case .hangs: return .hangs
        case .launches: return .launches
        }
    }

    private func mapSignature(
        _ sdk: AppStoreConnect_Swift_SDK.DiagnosticSignature,
        buildId: String
    ) -> DiagnosticSignatureInfo {
        let domainType: DiagnosticType
        switch sdk.attributes?.diagnosticType {
        case .diskWrites: domainType = .diskWrites
        case .hangs: domainType = .hangs
        case .launches: domainType = .launches
        case nil: domainType = .hangs
        }

        let direction: String?
        switch sdk.attributes?.insight?.direction {
        case .up: direction = "UP"
        case .down: direction = "DOWN"
        case .undefined: direction = "UNDEFINED"
        case nil: direction = nil
        }

        return DiagnosticSignatureInfo(
            id: sdk.id,
            buildId: buildId,
            diagnosticType: domainType,
            signature: sdk.attributes?.signature ?? "",
            weight: sdk.attributes?.weight ?? 0,
            insightDirection: direction
        )
    }

    private func flattenLogs(
        _ diagnosticLogs: DiagnosticLogs,
        signatureId: String
    ) -> [DiagnosticLogEntry] {
        guard let productData = diagnosticLogs.productData else { return [] }

        var entries: [DiagnosticLogEntry] = []
        for (productIndex, product) in productData.enumerated() {
            for (logIndex, log) in (product.diagnosticLogs ?? []).enumerated() {
                let meta = log.diagnosticMetaData
                let callStackSummary = extractCallStackSummary(from: log)

                entries.append(DiagnosticLogEntry(
                    id: "\(signatureId)-\(productIndex)-\(logIndex)",
                    signatureId: signatureId,
                    bundleId: meta?.bundleID,
                    appVersion: meta?.appVersion,
                    buildVersion: meta?.buildVersion,
                    osVersion: meta?.osVersion,
                    deviceType: meta?.deviceType,
                    event: meta?.event,
                    callStackSummary: callStackSummary
                ))
            }
        }
        return entries
    }

    private func extractCallStackSummary(from log: DiagnosticLogs.ProductDatum.DiagnosticLog) -> String? {
        guard let tree = log.callStackTree?.first,
              let stack = tree.callStacks?.first,
              let frames = stack.callStackRootFrames else {
            return nil
        }

        var summary: [String] = []
        var current: DiagnosticLogCallStackNode? = frames.first
        while let node = current, summary.count < 5 {
            if let name = node.symbolName {
                summary.append(name)
            }
            current = node.subFrames?.first
        }

        return summary.isEmpty ? nil : summary.joined(separator: " > ")
    }
}
