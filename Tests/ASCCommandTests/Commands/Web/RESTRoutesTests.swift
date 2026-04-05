import Foundation
import Testing
import Mockable
@testable import ASCCommand
@testable import Domain

@Suite
struct RESTRoutesTests {

    @Test func `apps list returns JSON with _links`() async throws {
        let mockRepo = MockAppRepository()
        given(mockRepo).listApps(limit: .any).willReturn(
            PaginatedResponse(data: [
                App(id: "42", name: "MyApp", bundleId: "com.test"),
            ])
        )
        let output = try await RESTHandlers.listApps(repo: mockRepo)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/apps/42/versions"))
        #expect(!normalized.contains("\"affordances\""))
    }

    @Test func `apps list returns data wrapper`() async throws {
        let mockRepo = MockAppRepository()
        given(mockRepo).listApps(limit: .any).willReturn(
            PaginatedResponse(data: [
                App(id: "1", name: "Test", bundleId: "com.test"),
            ])
        )
        let output = try await RESTHandlers.listApps(repo: mockRepo)
        #expect(output.contains("\"data\""))
    }

    @Test func `app get returns single app with _links`() async throws {
        let mockRepo = MockAppRepository()
        given(mockRepo).getApp(id: .any).willReturn(
            App(id: "42", name: "MyApp", bundleId: "com.test")
        )
        let output = try await RESTHandlers.getApp(id: "42", repo: mockRepo)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/apps/42/versions"))
    }

    @Test func `versions list returns JSON with _links`() async throws {
        let mockRepo = MockVersionRepository()
        given(mockRepo).listVersions(appId: .any).willReturn([
            AppStoreVersion(id: "v-1", appId: "42", versionString: "1.0", platform: .iOS, state: .prepareForSubmission),
        ])
        let output = try await RESTHandlers.listVersions(appId: "42", repo: mockRepo)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/versions/v-1/localizations"))
    }

    // MARK: - API Root

    @Test func `api root returns _links to all top-level resources`() throws {
        let output = try RESTHandlers.apiRoot()
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/apps"))
        #expect(normalized.contains("/api/v1/certificates"))
        #expect(normalized.contains("/api/v1/simulators"))
        #expect(normalized.contains("/api/v1/plugins"))
        #expect(normalized.contains("/api/v1/territories"))
    }

    // MARK: - Simulators

    @Test func `simulators list returns JSON with _links`() async throws {
        let mockRepo = MockSimulatorRepository()
        given(mockRepo).listSimulators(filter: .any).willReturn([
            Simulator(id: "ABC-123", name: "iPhone 15", state: .booted, runtime: "iOS 17.0"),
        ])
        let output = try await RESTHandlers.listSimulators(repo: mockRepo)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("\"data\""))
    }

    // MARK: - Builds

    @Test func `builds list returns JSON with _links`() async throws {
        let mockRepo = MockBuildRepository()
        given(mockRepo).listBuilds(appId: .any, platform: .any, version: .any, limit: .any).willReturn(
            PaginatedResponse(data: [
                Build(id: "b-1", version: "1.0", expired: false, processingState: .valid),
            ])
        )
        let output = try await RESTHandlers.listBuilds(appId: "42", repo: mockRepo)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("\"data\""))
    }

    // MARK: - TestFlight

    @Test func `testflight groups list returns JSON with _links`() async throws {
        let mockRepo = MockTestFlightRepository()
        given(mockRepo).listBetaGroups(appId: .any, limit: .any).willReturn(
            PaginatedResponse(data: [
                BetaGroup(id: "g-1", appId: "42", name: "External Testers", isInternalGroup: false),
            ])
        )
        let output = try await RESTHandlers.listBetaGroups(appId: "42", repo: mockRepo)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("\"data\""))
    }

    // MARK: - App Shots

    @Test func `templates list returns data wrapper`() async throws {
        let mockRepo = MockTemplateRepository()
        given(mockRepo).listTemplates(size: .any).willReturn([])
        let output = try await RESTHandlers.listTemplates(repo: mockRepo)
        #expect(output.contains("\"data\""))
    }

    @Test func `themes list returns data wrapper`() async throws {
        let mockRepo = MockThemeRepository()
        given(mockRepo).listThemes().willReturn([])
        let output = try await RESTHandlers.listThemes(repo: mockRepo)
        #expect(output.contains("\"data\""))
    }

    // MARK: - API Root includes app-shots

    @Test func `api root includes app-shots resources`() throws {
        let output = try RESTHandlers.apiRoot()
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("appShotsTemplates"))
        #expect(normalized.contains("appShotsThemes"))
    }
}