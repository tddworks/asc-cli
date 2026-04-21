import Foundation
import Testing
import Mockable
@testable import ASCCommand
@testable import Domain

@Suite
struct AppsControllerTests {

    @Test func `apps list with include icon attaches iconAsset per app`() async throws {
        let mockRepo = MockAppRepository()
        let asset = ImageAsset(
            templateUrl: "https://cdn.example.com/a/{w}x{h}bb.{f}",
            width: 512,
            height: 512
        )
        given(mockRepo).listApps(limit: .any).willReturn(
            PaginatedResponse(data: [
                App(id: "42", name: "MyApp", bundleId: "com.test"),
            ])
        )
        given(mockRepo).fetchAppIcon(appId: .any).willReturn(asset)

        let apps = try await AppsController.loadApps(repo: mockRepo, includeIcon: true)

        let formatter = OutputFormatter(format: .json, pretty: true)
        let output = try formatter.formatAgentItems(apps, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("\"iconAsset\""))
        #expect(normalized.contains("\"templateUrl\" : \"https://cdn.example.com/a/{w}x{h}bb.{f}\""))
        #expect(normalized.contains("\"width\" : 512"))
        #expect(normalized.contains("\"_links\""))
    }

    @Test func `app infos list returns JSON with _links and data wrapper`() async throws {
        let mockRepo = MockAppInfoRepository()
        given(mockRepo).listAppInfos(appId: .any).willReturn([
            AppInfo(id: "ai-1", appId: "42", primaryCategoryId: "6014"),
        ])
        let infos = try await mockRepo.listAppInfos(appId: "42")

        let formatter = OutputFormatter(format: .json, pretty: true)
        let output = try formatter.formatAgentItems(infos, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("\"data\""))
        #expect(normalized.contains("/api/v1/app-infos/ai-1/localizations"))
        #expect(!normalized.contains("\"affordances\""))
    }

    @Test func `app info localizations list returns JSON with _links and fields`() async throws {
        let mockRepo = MockAppInfoRepository()
        given(mockRepo).listLocalizations(appInfoId: .any).willReturn([
            AppInfoLocalization(
                id: "loc-1",
                appInfoId: "ai-1",
                locale: "en-US",
                name: "My App",
                subtitle: "Does things",
                privacyPolicyUrl: "https://example.com/privacy"
            ),
        ])
        let items = try await mockRepo.listLocalizations(appInfoId: "ai-1")

        let formatter = OutputFormatter(format: .json, pretty: true)
        let output = try formatter.formatAgentItems(items, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("\"data\""))
        #expect(normalized.contains("\"locale\" : \"en-US\""))
        #expect(normalized.contains("\"name\" : \"My App\""))
        #expect(normalized.contains("/api/v1/app-infos/ai-1/localizations"))
        #expect(normalized.contains("/api/v1/app-info-localizations/loc-1"))
        #expect(!normalized.contains("\"affordances\""))
    }

    @Test func `age rating get returns JSON with _links and data wrapper`() async throws {
        let mockRepo = MockAgeRatingDeclarationRepository()
        given(mockRepo).getDeclaration(appInfoId: .any).willReturn(
            AgeRatingDeclaration(id: "rating-1", appInfoId: "ai-1", isGambling: false)
        )
        let decl = try await mockRepo.getDeclaration(appInfoId: "ai-1")

        let formatter = OutputFormatter(format: .json, pretty: true)
        let output = try formatter.formatAgentItems([decl], affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("\"data\""))
        #expect(normalized.contains("\"id\" : \"rating-1\""))
        #expect(normalized.contains("\"appInfoId\" : \"ai-1\""))
        #expect(normalized.contains("/api/v1/age-rating/ai-1"))
        #expect(!normalized.contains("\"affordances\""))
    }

    @Test func `app info update returns updated record with category ids`() async throws {
        let mockRepo = MockAppInfoRepository()
        given(mockRepo)
            .updateCategories(
                id: .any,
                primaryCategoryId: .any,
                primarySubcategoryOneId: .any,
                primarySubcategoryTwoId: .any,
                secondaryCategoryId: .any,
                secondarySubcategoryOneId: .any,
                secondarySubcategoryTwoId: .any
            )
            .willReturn(AppInfo(
                id: "ai-1",
                appId: "app-1",
                primaryCategoryId: "FINANCE",
                secondaryCategoryId: "LIFESTYLE"
            ))

        let updated = try await mockRepo.updateCategories(
            id: "ai-1",
            primaryCategoryId: "FINANCE",
            primarySubcategoryOneId: nil,
            primarySubcategoryTwoId: nil,
            secondaryCategoryId: "LIFESTYLE",
            secondarySubcategoryOneId: nil,
            secondarySubcategoryTwoId: nil
        )

        let formatter = OutputFormatter(format: .json, pretty: true)
        let output = try formatter.formatAgentItems([updated], affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("\"primaryCategoryId\" : \"FINANCE\""))
        #expect(normalized.contains("\"secondaryCategoryId\" : \"LIFESTYLE\""))
        #expect(normalized.contains("/api/v1/app-categories/FINANCE"))
        #expect(normalized.contains("/api/v1/app-categories/LIFESTYLE"))
    }

    @Test func `apps list without include icon omits iconAsset`() async throws {
        let mockRepo = MockAppRepository()
        given(mockRepo).listApps(limit: .any).willReturn(
            PaginatedResponse(data: [
                App(id: "42", name: "MyApp", bundleId: "com.test"),
            ])
        )

        let apps = try await AppsController.loadApps(repo: mockRepo, includeIcon: false)

        let formatter = OutputFormatter(format: .json, pretty: true)
        let output = try formatter.formatAgentItems(apps, affordanceMode: .rest)
        #expect(!output.contains("\"iconAsset\""))
    }
}
