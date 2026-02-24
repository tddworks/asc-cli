@preconcurrency import AppStoreConnect_Swift_SDK
import Foundation
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKLocalizationRepositoryTests {

    // MARK: - listLocalizations

    @Test func `listLocalizations injects versionId into each localization`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppStoreVersionLocalizationsResponse(
            data: [
                AppStoreVersionLocalization(
                    type: .appStoreVersionLocalizations,
                    id: "loc-1",
                    attributes: .init(locale: "en-US")
                ),
                AppStoreVersionLocalization(
                    type: .appStoreVersionLocalizations,
                    id: "loc-2",
                    attributes: .init(locale: "zh-Hans")
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKLocalizationRepository(client: stub)
        let result = try await repo.listLocalizations(versionId: "v-42")

        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.versionId == "v-42" })
    }

    @Test func `listLocalizations maps locale from SDK attributes`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppStoreVersionLocalizationsResponse(
            data: [
                AppStoreVersionLocalization(
                    type: .appStoreVersionLocalizations,
                    id: "loc-1",
                    attributes: .init(locale: "fr-FR")
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKLocalizationRepository(client: stub)
        let result = try await repo.listLocalizations(versionId: "v-1")

        #expect(result[0].id == "loc-1")
        #expect(result[0].locale == "fr-FR")
    }

    // MARK: - createLocalization

    @Test func `createLocalization injects versionId into response`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppStoreVersionLocalizationResponse(
            data: AppStoreVersionLocalization(
                type: .appStoreVersionLocalizations,
                id: "loc-new",
                attributes: .init(locale: "en-US")
            ),
            links: .init(this: "")
        ))

        let repo = SDKLocalizationRepository(client: stub)
        let result = try await repo.createLocalization(versionId: "v-42", locale: "en-US")

        #expect(result.id == "loc-new")
        #expect(result.versionId == "v-42")
        #expect(result.locale == "en-US")
    }

    // MARK: - updateLocalization

    @Test func `updateLocalization returns localization with whatsNew from response`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppStoreVersionLocalizationResponse(
            data: AppStoreVersionLocalization(
                type: .appStoreVersionLocalizations,
                id: "loc-42",
                attributes: .init(locale: "en-US", whatsNew: "Bug fixes and performance improvements")
            ),
            links: .init(this: "")
        ))

        let repo = SDKLocalizationRepository(client: stub)
        let result = try await repo.updateLocalization(
            localizationId: "loc-42",
            whatsNew: "Bug fixes and performance improvements",
            description: nil,
            keywords: nil,
            marketingUrl: nil,
            supportUrl: nil,
            promotionalText: nil
        )

        #expect(result.id == "loc-42")
        #expect(result.whatsNew == "Bug fixes and performance improvements")
    }

    @Test func `updateLocalization maps all text fields from SDK response`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppStoreVersionLocalizationResponse(
            data: AppStoreVersionLocalization(
                type: .appStoreVersionLocalizations,
                id: "loc-1",
                attributes: .init(
                    description: "应用描述",
                    locale: "zh-Hans",
                    keywords: "关键词",
                    marketingURL: URL(string: "https://example.com"),
                    promotionalText: "促销文本",
                    supportURL: URL(string: "https://support.example.com"),
                    whatsNew: "新功能"
                )
            ),
            links: .init(this: "")
        ))

        let repo = SDKLocalizationRepository(client: stub)
        let result = try await repo.updateLocalization(
            localizationId: "loc-1",
            whatsNew: "新功能",
            description: "应用描述",
            keywords: "关键词",
            marketingUrl: "https://example.com",
            supportUrl: "https://support.example.com",
            promotionalText: "促销文本"
        )

        #expect(result.locale == "zh-Hans")
        #expect(result.whatsNew == "新功能")
        #expect(result.description == "应用描述")
        #expect(result.keywords == "关键词")
        #expect(result.marketingUrl == "https://example.com")
        #expect(result.supportUrl == "https://support.example.com")
        #expect(result.promotionalText == "促销文本")
    }
}
