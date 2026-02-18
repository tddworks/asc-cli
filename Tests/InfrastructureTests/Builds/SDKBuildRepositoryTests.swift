@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKBuildRepositoryTests {

    @Test func `listBuilds maps version and processingState`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(BuildsResponse(
            data: [
                AppStoreConnect_Swift_SDK.Build(
                    type: .builds,
                    id: "build-1",
                    attributes: .init(version: "42", processingState: .valid)
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKBuildRepository(client: stub)
        let result = try await repo.listBuilds(appId: nil, limit: nil)

        #expect(result.data[0].id == "build-1")
        #expect(result.data[0].version == "42")
        #expect(result.data[0].processingState == .valid)
    }

    @Test func `listBuilds maps all processing states`() async throws {
        let cases: [(AppStoreConnect_Swift_SDK.Build.Attributes.ProcessingState, Domain.Build.ProcessingState)] = [
            (.processing, .processing),
            (.failed, .failed),
            (.invalid, .invalid),
            (.valid, .valid),
        ]

        for (sdkState, domainState) in cases {
            let stub = StubAPIClient()
            stub.willReturn(BuildsResponse(
                data: [
                    AppStoreConnect_Swift_SDK.Build(type: .builds, id: "b-1", attributes: .init(processingState: sdkState)),
                ],
                links: .init(this: "")
            ))

            let repo = SDKBuildRepository(client: stub)
            let result = try await repo.listBuilds(appId: nil, limit: nil)

            #expect(result.data[0].processingState == domainState)
        }
    }
}
