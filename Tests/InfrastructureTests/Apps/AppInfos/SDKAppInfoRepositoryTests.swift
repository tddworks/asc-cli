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

    @Test func `listAppInfos maps appStoreAgeRating from attributes`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppInfosResponse(
            data: [
                AppInfo(
                    type: .appInfos,
                    id: "info-1",
                    attributes: .init(appStoreAgeRating: .fourPlus)
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKAppInfoRepository(client: stub)
        let result = try await repo.listAppInfos(appId: "app-1")

        #expect(result[0].appStoreAgeRating == "FOUR_PLUS")
    }

    @Test func `listAppInfos maps appStoreState and state from attributes`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppInfosResponse(
            data: [
                AppInfo(
                    type: .appInfos,
                    id: "info-1",
                    attributes: .init(appStoreState: .readyForSale, state: .readyForDistribution)
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKAppInfoRepository(client: stub)
        let result = try await repo.listAppInfos(appId: "app-1")

        #expect(result[0].appStoreState == "READY_FOR_SALE")
        #expect(result[0].state == "READY_FOR_DISTRIBUTION")
    }

    @Test func `listAppInfos maps primary and secondary category ids from relationships`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppInfosResponse(
            data: [
                AppInfo(
                    type: .appInfos,
                    id: "info-1",
                    relationships: .init(
                        primaryCategory: .init(data: .init(type: .appCategories, id: "6014")),
                        primarySubcategoryOne: .init(data: .init(type: .appCategories, id: "7001")),
                        primarySubcategoryTwo: .init(data: .init(type: .appCategories, id: "7002")),
                        secondaryCategory: .init(data: .init(type: .appCategories, id: "6015")),
                        secondarySubcategoryOne: .init(data: .init(type: .appCategories, id: "7003")),
                        secondarySubcategoryTwo: .init(data: .init(type: .appCategories, id: "7004"))
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKAppInfoRepository(client: stub)
        let result = try await repo.listAppInfos(appId: "app-1")

        #expect(result[0].primaryCategoryId == "6014")
        #expect(result[0].primarySubcategoryOneId == "7001")
        #expect(result[0].primarySubcategoryTwoId == "7002")
        #expect(result[0].secondaryCategoryId == "6015")
        #expect(result[0].secondarySubcategoryOneId == "7003")
        #expect(result[0].secondarySubcategoryTwoId == "7004")
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

    // MARK: - createLocalization

    @Test func `createLocalization injects appInfoId into response`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppInfoLocalizationResponse(
            data: AppInfoLocalization(
                type: .appInfoLocalizations,
                id: "loc-new",
                attributes: .init(locale: "en-US", name: "My App")
            ),
            links: .init(this: "")
        ))

        let repo = SDKAppInfoRepository(client: stub)
        let result = try await repo.createLocalization(appInfoId: "info-42", locale: "en-US", name: "My App")

        #expect(result.id == "loc-new")
        #expect(result.appInfoId == "info-42")
        #expect(result.locale == "en-US")
        #expect(result.name == "My App")
    }

    // MARK: - updateLocalization

    @Test func `updateLocalization injects appInfoId from response relationships`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppInfoLocalizationResponse(
            data: AppInfoLocalization(
                type: .appInfoLocalizations,
                id: "loc-1",
                attributes: .init(locale: "en-US", name: "Updated App", subtitle: "New subtitle"),
                relationships: .init(appInfo: .init(data: .init(type: .appInfos, id: "info-42")))
            ),
            links: .init(this: "")
        ))

        let repo = SDKAppInfoRepository(client: stub)
        let result = try await repo.updateLocalization(
            id: "loc-1", name: "Updated App", subtitle: "New subtitle", privacyPolicyUrl: nil, privacyChoicesUrl: nil, privacyPolicyText: nil
        )

        #expect(result.id == "loc-1")
        #expect(result.appInfoId == "info-42")
        #expect(result.name == "Updated App")
        #expect(result.subtitle == "New subtitle")
    }

    @Test func `updateLocalization defaults appInfoId to empty when no relationship`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppInfoLocalizationResponse(
            data: AppInfoLocalization(
                type: .appInfoLocalizations,
                id: "loc-2",
                attributes: .init(locale: "de-DE", name: "Meine App")
            ),
            links: .init(this: "")
        ))

        let repo = SDKAppInfoRepository(client: stub)
        let result = try await repo.updateLocalization(id: "loc-2", name: "Meine App", subtitle: nil, privacyPolicyUrl: nil, privacyChoicesUrl: nil, privacyPolicyText: nil)

        #expect(result.appInfoId == "")
    }

    @Test func `listAppInfos maps primary category id from relationships`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppInfosResponse(
            data: [
                AppInfo(
                    type: .appInfos,
                    id: "info-1",
                    relationships: .init(primaryCategory: .init(data: .init(type: .appCategories, id: "6014")))
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKAppInfoRepository(client: stub)
        let result = try await repo.listAppInfos(appId: "app-1")

        #expect(result[0].primaryCategoryId == "6014")
    }

    @Test func `listLocalizations maps privacyChoicesUrl and privacyPolicyText from SDK attributes`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppInfoLocalizationsResponse(
            data: [
                AppInfoLocalization(
                    type: .appInfoLocalizations,
                    id: "loc-1",
                    attributes: .init(
                        locale: "en-US",
                        privacyChoicesURL: "https://example.com/choices",
                        privacyPolicyText: "Our privacy policy"
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKAppInfoRepository(client: stub)
        let result = try await repo.listLocalizations(appInfoId: "info-1")

        #expect(result[0].privacyChoicesUrl == "https://example.com/choices")
        #expect(result[0].privacyPolicyText == "Our privacy policy")
    }
}
