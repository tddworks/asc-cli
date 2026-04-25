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

    @Test func `plugins updates list returns outdated entries with apply links`() async throws {
        let mockRepo = MockPluginRepository()
        given(mockRepo).listOutdated().willReturn([
            PluginUpdate(name: "Hello", installedVersion: "1.0.0", latestVersion: "1.2.0"),
        ])
        let output = try await PluginsUpdates.parse(["--pretty"]).execute(repo: mockRepo, affordanceMode: .rest)
        #expect(output.contains("\"_links\""))
        #expect(output.contains("\"name\" : \"Hello\""))
        #expect(output.contains("\"installedVersion\" : \"1.0.0\""))
        #expect(output.contains("\"latestVersion\" : \"1.2.0\""))
    }

    @Test func `plugins update returns the freshly installed plugin`() async throws {
        let mockRepo = MockPluginRepository()
        given(mockRepo).update(name: .value("Hello")).willReturn(
            Plugin(id: "Hello.plugin", name: "Hello", version: "1.2.0", isInstalled: true, slug: "Hello.plugin")
        )
        let output = try await PluginsUpdate.parse(["--name", "Hello", "--pretty"]).execute(repo: mockRepo, affordanceMode: .rest)
        #expect(output.contains("\"_links\""))
        #expect(output.contains("\"version\" : \"1.2.0\""))
        #expect(output.contains("\"isInstalled\" : true"))
    }

    @Test func `plugins install returns the installed plugin in data wrapper`() async throws {
        let mockRepo = MockPluginRepository()
        given(mockRepo).install(name: .any).willReturn(
            Plugin(id: "Hello.plugin", name: "Hello", version: "1.0", author: "me", isInstalled: true, slug: "Hello.plugin")
        )
        let output = try await PluginsInstall.parse(["--name", "Hello.plugin", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        #expect(output.contains("\"data\""))
        #expect(output.contains("\"name\" : \"Hello\""))
        #expect(output.contains("\"isInstalled\" : true"))
    }

    @Test func `plugins market search returns filtered list under data wrapper`() async throws {
        let mockRepo = MockPluginRepository()
        given(mockRepo).searchAvailable(query: .value("hello")).willReturn([
            Plugin(id: "Hello.plugin", name: "Hello", version: "1.0", author: "me"),
        ])
        let output = try await MarketSearch.parse(["--query", "hello", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        #expect(output.contains("\"data\""))
        #expect(output.contains("\"name\" : \"Hello\""))
    }

    @Test func `auth list returns accounts JSON wrapped in data`() async throws {
        let storage = MockAuthStorage()
        given(storage).loadAll().willReturn([
            ConnectAccount(name: "personal", keyID: "K1", issuerID: "I1", isActive: true),
            ConnectAccount(name: "work", keyID: "K2", issuerID: "I2", isActive: false),
        ])
        let output = try await AuthList.parse(["--pretty"]).execute(storage: storage, affordanceMode: .rest)
        #expect(output.contains("\"data\""))
        #expect(output.contains("\"name\" : \"personal\""))
        #expect(output.contains("\"name\" : \"work\""))
        #expect(output.contains("\"isActive\" : true"))
    }

    @Test func `auth login returns AuthStatus with the saved name`() async throws {
        let storage = MockAuthStorage()
        given(storage).save(.any, name: .any).willReturn(())
        given(storage).setActive(name: .any).willReturn(())
        let output = try await AuthLogin.parse([
            "--key-id", "KEY",
            "--issuer-id", "ISSUER",
            "--private-key=-----BEGIN PRIVATE KEY-----\nA\n-----END PRIVATE KEY-----",
            "--name", "personal",
            "--pretty",
        ]).execute(storage: storage, affordanceMode: .rest)
        #expect(output.contains("\"name\" : \"personal\""))
        #expect(output.contains("\"keyID\" : \"KEY\""))
        #expect(output.contains("\"source\" : \"file\""))
    }

    @Test func `age-rating update returns JSON with _links`() async throws {
        let mockRepo = MockAgeRatingDeclarationRepository()
        given(mockRepo).updateDeclaration(id: .any, update: .any).willReturn(
            AgeRatingDeclaration(id: "decl-1", appInfoId: "info-42", isAdvertising: false)
        )
        let output = try await AgeRatingUpdate
            .parse(["--declaration-id", "decl-1", "--advertising", "false", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/age-rating/decl-1"))
        #expect(!normalized.contains("\"affordances\""))
    }

    @Test func `apps update returns JSON with _links and contentRightsDeclaration`() async throws {
        let mockRepo = MockAppRepository()
        given(mockRepo).updateContentRights(appId: .any, declaration: .any).willReturn(
            App(id: "42", name: "Bakery", bundleId: "com.example", contentRightsDeclaration: .doesNotUseThirdPartyContent)
        )
        let output = try await AppsUpdate
            .parse(["--app-id", "42", "--content-rights-declaration", "DOES_NOT_USE_THIRD_PARTY_CONTENT", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/apps/42"))
        #expect(normalized.contains("\"contentRightsDeclaration\" : \"DOES_NOT_USE_THIRD_PARTY_CONTENT\""))
        #expect(!normalized.contains("\"affordances\""))
    }

    @Test func `versions update returns JSON with _links`() async throws {
        let mockRepo = MockVersionRepository()
        given(mockRepo).updateVersion(id: .any, versionString: .any).willReturn(
            AppStoreVersion(id: "v-1", appId: "42", versionString: "1.5", platform: .iOS, state: .prepareForSubmission)
        )
        let output = try await VersionsUpdate
            .parse(["--version-id", "v-1", "--version", "1.5", "--pretty"])
            .execute(repo: mockRepo, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("/api/v1/versions/v-1"))
        #expect(!normalized.contains("\"affordances\""))
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
