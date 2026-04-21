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
