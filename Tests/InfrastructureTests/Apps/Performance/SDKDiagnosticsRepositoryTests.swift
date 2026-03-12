@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKDiagnosticsRepositoryTests {

    private func makeSDKSignature(
        id: String = "sig-1",
        diagnosticType: AppStoreConnect_Swift_SDK.DiagnosticSignature.Attributes.DiagnosticType = .hangs,
        signature: String = "main thread hang",
        weight: Double = 45.2,
        insightDirection: DiagnosticInsightDirection? = .up
    ) -> AppStoreConnect_Swift_SDK.DiagnosticSignature {
        AppStoreConnect_Swift_SDK.DiagnosticSignature(
            type: .diagnosticSignatures,
            id: id,
            attributes: .init(
                diagnosticType: diagnosticType,
                signature: signature,
                weight: weight,
                insight: insightDirection.map { DiagnosticInsight(insightType: .trend, direction: $0) }
            )
        )
    }

    @Test func `listSignatures maps SDK signatures and injects buildId`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(DiagnosticSignaturesResponse(
            data: [makeSDKSignature(id: "sig-1", diagnosticType: .hangs, signature: "hang in layoutSubviews", weight: 33.5)],
            links: .init(this: "")
        ))

        let repo = SDKDiagnosticsRepository(client: stub)
        let result = try await repo.listSignatures(buildId: "build-1", diagnosticType: nil)

        #expect(result.count == 1)
        #expect(result[0].id == "sig-1")
        #expect(result[0].buildId == "build-1")
        #expect(result[0].diagnosticType == .hangs)
        #expect(result[0].signature == "hang in layoutSubviews")
        #expect(result[0].weight == 33.5)
        #expect(result[0].insightDirection == "UP")
    }

    @Test func `listSignatures injects buildId into every signature`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(DiagnosticSignaturesResponse(
            data: [
                makeSDKSignature(id: "sig-1"),
                makeSDKSignature(id: "sig-2"),
            ],
            links: .init(this: "")
        ))

        let repo = SDKDiagnosticsRepository(client: stub)
        let result = try await repo.listSignatures(buildId: "build-99", diagnosticType: nil)

        #expect(result.allSatisfy { $0.buildId == "build-99" })
    }

    @Test func `listSignatures maps nil insight as nil direction`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(DiagnosticSignaturesResponse(
            data: [makeSDKSignature(insightDirection: nil)],
            links: .init(this: "")
        ))

        let repo = SDKDiagnosticsRepository(client: stub)
        let result = try await repo.listSignatures(buildId: "build-1", diagnosticType: nil)

        #expect(result[0].insightDirection == nil)
    }

    @Test func `listSignatures maps diskWrites diagnostic type`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(DiagnosticSignaturesResponse(
            data: [makeSDKSignature(diagnosticType: .diskWrites)],
            links: .init(this: "")
        ))

        let repo = SDKDiagnosticsRepository(client: stub)
        let result = try await repo.listSignatures(buildId: "build-1", diagnosticType: .diskWrites)

        #expect(result[0].diagnosticType == .diskWrites)
    }

    @Test func `listSignatures maps launches diagnostic type`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(DiagnosticSignaturesResponse(
            data: [makeSDKSignature(diagnosticType: .launches)],
            links: .init(this: "")
        ))

        let repo = SDKDiagnosticsRepository(client: stub)
        let result = try await repo.listSignatures(buildId: "build-1", diagnosticType: .launches)

        #expect(result[0].diagnosticType == .launches)
    }

    @Test func `listSignatures maps DOWN insight direction`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(DiagnosticSignaturesResponse(
            data: [makeSDKSignature(insightDirection: .down)],
            links: .init(this: "")
        ))

        let repo = SDKDiagnosticsRepository(client: stub)
        let result = try await repo.listSignatures(buildId: "build-1", diagnosticType: nil)

        #expect(result[0].insightDirection == "DOWN")
    }

    @Test func `listSignatures maps UNDEFINED insight direction`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(DiagnosticSignaturesResponse(
            data: [makeSDKSignature(insightDirection: .undefined)],
            links: .init(this: "")
        ))

        let repo = SDKDiagnosticsRepository(client: stub)
        let result = try await repo.listSignatures(buildId: "build-1", diagnosticType: nil)

        #expect(result[0].insightDirection == "UNDEFINED")
    }

    @Test func `listSignatures maps nil diagnosticType as hangs`() async throws {
        let stub = StubAPIClient()
        let sig = AppStoreConnect_Swift_SDK.DiagnosticSignature(
            type: .diagnosticSignatures,
            id: "sig-nil",
            attributes: .init(diagnosticType: nil, signature: "unknown", weight: 10.0)
        )
        stub.willReturn(DiagnosticSignaturesResponse(data: [sig], links: .init(this: "")))

        let repo = SDKDiagnosticsRepository(client: stub)
        let result = try await repo.listSignatures(buildId: "build-1", diagnosticType: nil)

        #expect(result[0].diagnosticType == .hangs)
    }

    @Test func `listLogs extracts call stack summary from frames`() async throws {
        let stub = StubAPIClient()
        let logs = DiagnosticLogs(
            productData: [
                .init(
                    signatureID: "sig-1",
                    diagnosticInsights: nil,
                    diagnosticLogs: [
                        .init(
                            callStackTree: [
                                .init(
                                    isCallStackPerThread: false,
                                    callStacks: [
                                        .init(callStackRootFrames: [
                                            DiagnosticLogCallStackNode(
                                                symbolName: "main",
                                                subFrames: [
                                                    DiagnosticLogCallStackNode(
                                                        symbolName: "UIApplicationMain",
                                                        subFrames: [
                                                            DiagnosticLogCallStackNode(symbolName: "layoutSubviews")
                                                        ]
                                                    )
                                                ]
                                            )
                                        ])
                                    ]
                                )
                            ],
                            diagnosticMetaData: .init(bundleID: "com.test")
                        )
                    ]
                )
            ],
            version: "1.0"
        )
        stub.willReturn(logs)

        let repo = SDKDiagnosticsRepository(client: stub)
        let result = try await repo.listLogs(signatureId: "sig-1")

        #expect(result[0].callStackSummary == "main > UIApplicationMain > layoutSubviews")
    }

    @Test func `listLogs returns nil callStackSummary when no call stack tree`() async throws {
        let stub = StubAPIClient()
        let logs = DiagnosticLogs(
            productData: [
                .init(
                    signatureID: "sig-1",
                    diagnosticInsights: nil,
                    diagnosticLogs: [
                        .init(callStackTree: nil, diagnosticMetaData: .init(bundleID: "com.test"))
                    ]
                )
            ],
            version: "1.0"
        )
        stub.willReturn(logs)

        let repo = SDKDiagnosticsRepository(client: stub)
        let result = try await repo.listLogs(signatureId: "sig-1")

        #expect(result[0].callStackSummary == nil)
    }

    @Test func `listLogs maps diagnostic logs and injects signatureId`() async throws {
        let stub = StubAPIClient()
        let logs = DiagnosticLogs(
            productData: [
                .init(
                    signatureID: "sig-1",
                    diagnosticInsights: nil,
                    diagnosticLogs: [
                        .init(
                            callStackTree: nil,
                            diagnosticMetaData: .init(
                                bundleID: "com.example.app",
                                event: "hang",
                                osVersion: "iOS 17.0",
                                appVersion: "2.0",
                                writesCaused: nil,
                                deviceType: "iPhone15,2",
                                platformArchitecture: "arm64",
                                eventDetail: nil,
                                buildVersion: "100"
                            )
                        )
                    ]
                )
            ],
            version: "1.0"
        )
        stub.willReturn(logs)

        let repo = SDKDiagnosticsRepository(client: stub)
        let result = try await repo.listLogs(signatureId: "sig-1")

        #expect(result.count == 1)
        #expect(result[0].signatureId == "sig-1")
        #expect(result[0].bundleId == "com.example.app")
        #expect(result[0].appVersion == "2.0")
        #expect(result[0].buildVersion == "100")
        #expect(result[0].osVersion == "iOS 17.0")
        #expect(result[0].deviceType == "iPhone15,2")
        #expect(result[0].event == "hang")
    }

    @Test func `listLogs returns empty when no productData`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(DiagnosticLogs(productData: nil, version: "1.0"))

        let repo = SDKDiagnosticsRepository(client: stub)
        let result = try await repo.listLogs(signatureId: "sig-1")

        #expect(result.isEmpty)
    }
}
