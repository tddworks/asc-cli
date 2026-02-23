@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKAppInfoRepositoryTests {

    // MARK: - listAppInfos

    @Test func `listAppInfos injects appId into each app info`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppInfosResponse(
            data: [
                AppInfo(type: .appInfos, id: "info-1"),
                AppInfo(type: .appInfos, id: "info-2"),
            ],
            links: .init(this: "")
        ))

        let repo = SDKAppInfoRepository(client: stub)
        let result = try await repo.listAppInfos(appId: "app-99")

        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.appId == "app-99" })
    }

    @Test func `listAppInfos maps id from SDK response`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppInfosResponse(
            data: [AppInfo(type: .appInfos, id: "info-abc")],
            links: .init(this: "")
        ))

        let repo = SDKAppInfoRepository(client: stub)
        let result = try await repo.listAppInfos(appId: "app-1")

        #expect(result[0].id == "info-abc")
    }

    // MARK: - listLocalizations

    @Test func `listLocalizations injects appInfoId into each localization`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppInfoLocalizationsResponse(
            data: [
                AppInfoLocalization(type: .appInfoLocalizations, id: "loc-1", attributes: .init(locale: "en-US")),
                AppInfoLocalization(type: .appInfoLocalizations, id: "loc-2", attributes: .init(locale: "zh-Hans")),
            ],
            links: .init(this: "")
        ))

        let repo = SDKAppInfoRepository(client: stub)
        let result = try await repo.listLocalizations(appInfoId: "info-42")

        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.appInfoId == "info-42" })
    }

    @Test func `listLocalizations maps locale name and subtitle from SDK attributes`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppInfoLocalizationsResponse(
            data: [
                AppInfoLocalization(
                    type: .appInfoLocalizations,
                    id: "loc-1",
                    attributes: .init(locale: "fr-FR", name: "Mon App", subtitle: "Fait des choses")
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKAppInfoRepository(client: stub)
        let result = try await repo.listLocalizations(appInfoId: "info-1")

        #expect(result[0].locale == "fr-FR")
        #expect(result[0].name == "Mon App")
        #expect(result[0].subtitle == "Fait des choses")
    }
}
