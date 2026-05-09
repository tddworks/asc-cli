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
        let result = try await repo.listBuilds(appId: nil, platform: nil, version: nil, limit: nil)

        #expect(result.data[0].id == "build-1")
        #expect(result.data[0].buildNumber == "42")
        #expect(result.data[0].processingState == .valid)
    }

    @Test func `listBuilds maps preReleaseVersion to version and platform`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(BuildsResponse(
            data: [
                AppStoreConnect_Swift_SDK.Build(
                    type: .builds,
                    id: "build-1",
                    attributes: .init(version: "42", processingState: .valid),
                    relationships: .init(preReleaseVersion: .init(data: .init(type: .preReleaseVersions, id: "prv-1")))
                ),
            ],
            included: [
                .prereleaseVersion(PrereleaseVersion(
                    type: .preReleaseVersions,
                    id: "prv-1",
                    attributes: .init(version: "1.2.0", platform: .ios)
                ))
            ],
            links: .init(this: "")
        ))

        let repo = SDKBuildRepository(client: stub)
        let result = try await repo.listBuilds(appId: nil, platform: nil, version: nil, limit: nil)

        #expect(result.data[0].version == "1.2.0")
        #expect(result.data[0].buildNumber == "42")
        #expect(result.data[0].platform == .iOS)
    }

    @Test func `listBuilds without preReleaseVersion falls back to build string as version`() async throws {
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
        let result = try await repo.listBuilds(appId: nil, platform: nil, version: nil, limit: nil)

        #expect(result.data[0].version == "42")
        #expect(result.data[0].buildNumber == "42")
        #expect(result.data[0].platform == nil)
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
            let result = try await repo.listBuilds(appId: nil, platform: nil, version: nil, limit: nil)

            #expect(result.data[0].processingState == domainState)
        }
    }

    @Test func `listBuilds with appId filter returns matching builds`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(BuildsResponse(
            data: [
                AppStoreConnect_Swift_SDK.Build(
                    type: .builds, id: "build-app-1",
                    attributes: .init(version: "5", processingState: .valid)
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKBuildRepository(client: stub)
        let result = try await repo.listBuilds(appId: "app-42", platform: nil, version: nil, limit: nil)

        #expect(result.data.count == 1)
        #expect(result.data[0].id == "build-app-1")
    }

    // MARK: - getBuild

    @Test func `getBuild maps build id version and processingState`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(BuildResponse(
            data: AppStoreConnect_Swift_SDK.Build(
                type: .builds, id: "build-99",
                attributes: .init(version: "100", processingState: .valid)
            ),
            links: .init(this: "")
        ))

        let repo = SDKBuildRepository(client: stub)
        let result = try await repo.getBuild(id: "build-99")

        #expect(result.id == "build-99")
        #expect(result.version == "100")
        #expect(result.processingState == .valid)
    }

    // MARK: - addBetaGroups / removeBetaGroups

    @Test func `addBetaGroups succeeds without error`() async throws {
        let stub = StubAPIClient()
        let repo = SDKBuildRepository(client: stub)
        try await repo.addBetaGroups(buildId: "build-1", betaGroupIds: ["bg-1", "bg-2"])
        #expect(stub.voidRequestCalled)
    }

    @Test func `removeBetaGroups succeeds without error`() async throws {
        let stub = StubAPIClient()
        let repo = SDKBuildRepository(client: stub)
        try await repo.removeBetaGroups(buildId: "build-1", betaGroupIds: ["bg-1"])
        #expect(stub.voidRequestCalled)
    }

    // MARK: - Encryption compliance

    @Test func `getBuild maps usesNonExemptEncryption from SDK attributes`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(BuildResponse(
            data: AppStoreConnect_Swift_SDK.Build(
                type: .builds, id: "build-1",
                attributes: .init(version: "42", processingState: .valid, usesNonExemptEncryption: false)
            ),
            links: .init(this: "")
        ))

        let repo = SDKBuildRepository(client: stub)
        let result = try await repo.getBuild(id: "build-1")

        #expect(result.usesNonExemptEncryption == false)
    }

    @Test func `getBuild leaves usesNonExemptEncryption nil when ASC has no answer yet`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(BuildResponse(
            data: AppStoreConnect_Swift_SDK.Build(
                type: .builds, id: "build-1",
                attributes: .init(version: "42", processingState: .valid)
            ),
            links: .init(this: "")
        ))

        let repo = SDKBuildRepository(client: stub)
        let result = try await repo.getBuild(id: "build-1")

        #expect(result.usesNonExemptEncryption == nil)
        #expect(result.isMissingEncryptionCompliance == true)
    }

    @Test func `updateBuildEncryptionCompliance returns build with the new flag`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(BuildResponse(
            data: AppStoreConnect_Swift_SDK.Build(
                type: .builds, id: "build-1",
                attributes: .init(version: "42", processingState: .valid, usesNonExemptEncryption: false)
            ),
            links: .init(this: "")
        ))

        let repo = SDKBuildRepository(client: stub)
        let result = try await repo.updateBuildEncryptionCompliance(buildId: "build-1", usesNonExemptEncryption: false)

        #expect(result.id == "build-1")
        #expect(result.usesNonExemptEncryption == false)
        #expect(result.isMissingEncryptionCompliance == false)
    }
}
