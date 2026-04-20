import Foundation
import Testing
import Mockable
@testable import ASCCommand
@testable import Domain

@Suite
struct RESTRoutesTests {

    private static let formatter = OutputFormatter(format: .json, pretty: true)

    // MARK: - Apps

    @Test func `apps list returns JSON with _links`() async throws {
        let mockRepo = MockAppRepository()
        given(mockRepo).listApps(limit: .any).willReturn(
            PaginatedResponse(data: [App(id: "42", name: "MyApp", bundleId: "com.test")])
        )
        let output = try await AppsList.parse(["--pretty"]).execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/apps/42/versions"))
        #expect(!normalized.contains("\"affordances\""))
    }

    @Test func `apps list returns data wrapper`() async throws {
        let mockRepo = MockAppRepository()
        given(mockRepo).listApps(limit: .any).willReturn(
            PaginatedResponse(data: [App(id: "1", name: "Test", bundleId: "com.test")])
        )
        let output = try await AppsList.parse(["--pretty"]).execute(repo: mockRepo, affordanceMode: .rest)
        #expect(output.contains("\"data\""))
    }

    // MARK: - Versions

    @Test func `versions list returns JSON with _links`() async throws {
        let mockRepo = MockVersionRepository()
        given(mockRepo).listVersions(appId: .any).willReturn([
            AppStoreVersion(id: "v-1", appId: "42", versionString: "1.0", platform: .iOS, state: .prepareForSubmission),
        ])
        let output = try await VersionsList.parse(["--app-id", "42", "--pretty"]).execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/versions/v-1/localizations"))
    }

    // MARK: - Version Localizations

    @Test func `version localizations list returns JSON with _links`() async throws {
        let mockRepo = MockVersionLocalizationRepository()
        given(mockRepo).listLocalizations(versionId: .any).willReturn([
            AppStoreVersionLocalization(id: "loc-1", versionId: "v-1", locale: "en-US", description: "A great app"),
        ])
        let output = try await VersionLocalizationsList.parse(["--version-id", "v-1", "--pretty"]).execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("\"locale\" : \"en-US\""))
        #expect(normalized.contains("\"description\" : \"A great app\""))
        #expect(!normalized.contains("\"affordances\""))
    }

    // MARK: - API Root

    @Test func `api root returns _links to all top-level resources`() throws {
        let output = try Self.formatter.formatAgentItems([APIRoot()], headers: [], rowMapper: { _ in [] }, affordanceMode: .rest)
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
        let output = try await SimulatorsList.parse(["--pretty"]).execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("\"data\""))
    }

    // MARK: - Builds

    @Test func `builds list returns JSON with _links`() async throws {
        let mockRepo = MockBuildRepository()
        given(mockRepo).listBuilds(appId: .any, platform: .any, version: .any, limit: .any).willReturn(
            PaginatedResponse(data: [Build(id: "b-1", version: "1.0", expired: false, processingState: .valid)])
        )
        let output = try await BuildsList.parse(["--app-id", "42", "--pretty"]).execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("\"data\""))
    }

    // MARK: - TestFlight

    @Test func `testflight groups list returns JSON with _links`() async throws {
        let mockRepo = MockTestFlightRepository()
        given(mockRepo).listBetaGroups(appId: .any, limit: .any).willReturn(
            PaginatedResponse(data: [BetaGroup(id: "g-1", appId: "42", name: "External Testers", isInternalGroup: false)])
        )
        let output = try await BetaGroupsList.parse(["--app-id", "42", "--pretty"]).execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("\"data\""))
    }

    // MARK: - App Shots

    @Test func `templates list returns data wrapper`() async throws {
        let mockRepo = MockTemplateRepository()
        given(mockRepo).listTemplates(size: .any).willReturn([])
        let output = try await AppShotsTemplatesList.parse(["--pretty"]).execute(repo: mockRepo, affordanceMode: .rest)
        #expect(output.contains("\"data\""))
    }

    @Test func `themes list returns data wrapper`() async throws {
        let mockRepo = MockThemeRepository()
        given(mockRepo).listThemes().willReturn([])
        let output = try await AppShotsThemesList.parse(["--pretty"]).execute(repo: mockRepo, affordanceMode: .rest)
        #expect(output.contains("\"data\""))
    }

    // MARK: - Review Submissions

    @Test func `review submissions list returns JSON with _links`() async throws {
        let mockRepo = MockSubmissionRepository()
        given(mockRepo).listSubmissions(appId: .any, states: .any, limit: .any).willReturn([
            ReviewSubmission(id: "sub-1", appId: "42", platform: .iOS, state: .waitingForReview),
        ])
        let output = try await ReviewSubmissionsList
            .parse(["--app-id", "42", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/apps/42/versions"))
        #expect(!normalized.contains("\"affordances\""))
    }

    @Test func `api root includes reviewSubmissions resource`() throws {
        let output = try Self.formatter.formatAgentItems([APIRoot()], headers: [], rowMapper: { _ in [] }, affordanceMode: .rest)
        #expect(output.contains("reviewSubmissions"))
    }

    // MARK: - Certificates REST filters

    @Test func `certificates list accepts limit via rest mode`() async throws {
        let mockRepo = MockCertificateRepository()
        given(mockRepo).listCertificates(certificateType: .any, limit: .value(200)).willReturn([
            Certificate(id: "cert-1", name: "Dist", certificateType: .iosDistribution),
        ])
        let output = try await CertificatesList
            .parse(["--limit", "200", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        #expect(output.contains("\"_links\""))
        #expect(output.contains("cert-1"))
    }

    @Test func `api root includes app-shots resources`() throws {
        let output = try Self.formatter.formatAgentItems([APIRoot()], headers: [], rowMapper: { _ in [] }, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("appShotsTemplates"))
        #expect(normalized.contains("appShotsThemes"))
    }
}
