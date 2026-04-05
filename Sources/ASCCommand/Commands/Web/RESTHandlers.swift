import Domain
import Foundation

/// REST API handlers that reuse CLI command `execute()` methods.
///
/// Each handler constructs a command via `parse()`, injects the repository,
/// and calls `execute(repo:, affordanceMode: .rest)`. Zero duplication —
/// the command owns the fetch + format logic, REST just sets the mode.
enum RESTHandlers {

    private static let formatter = OutputFormatter(format: .json, pretty: true)

    // MARK: - API Root

    static func apiRoot() throws -> String {
        let root = APIRoot()
        return try formatter.formatAgentItems(
            [root],
            headers: [],
            rowMapper: { _ in [] },
            affordanceMode: .rest
        )
    }

    // MARK: - Apps

    static func listApps(repo: any AppRepository, limit: Int? = nil) async throws -> String {
        let cmd = try AppsList.parse(["--pretty"])
        return try await cmd.execute(repo: repo, affordanceMode: .rest)
    }

    static func getApp(id: String, repo: any AppRepository) async throws -> String {
        // No CLI command for single app get — format directly
        let app = try await repo.getApp(id: id)
        return try formatter.formatAgentItems(
            [app],
            headers: [],
            rowMapper: { _ in [] },
            affordanceMode: .rest
        )
    }

    // MARK: - Versions

    static func listVersions(appId: String, repo: any VersionRepository) async throws -> String {
        let cmd = try VersionsList.parse(["--app-id", appId, "--pretty"])
        return try await cmd.execute(repo: repo, affordanceMode: .rest)
    }

    // MARK: - Builds

    static func listBuilds(appId: String, repo: any BuildRepository) async throws -> String {
        let cmd = try BuildsList.parse(["--app-id", appId, "--pretty"])
        return try await cmd.execute(repo: repo, affordanceMode: .rest)
    }

    // MARK: - TestFlight

    static func listBetaGroups(appId: String, repo: any TestFlightRepository) async throws -> String {
        let cmd = try BetaGroupsList.parse(["--app-id", appId, "--pretty"])
        return try await cmd.execute(repo: repo, affordanceMode: .rest)
    }

    // MARK: - Reviews

    static func listReviews(appId: String, repo: any CustomerReviewRepository) async throws -> String {
        let cmd = try ReviewsList.parse(["--app-id", appId, "--pretty"])
        return try await cmd.execute(repo: repo, affordanceMode: .rest)
    }

    // MARK: - IAP

    static func listIAP(appId: String, repo: any InAppPurchaseRepository) async throws -> String {
        let cmd = try IAPList.parse(["--app-id", appId, "--pretty"])
        return try await cmd.execute(repo: repo, affordanceMode: .rest)
    }

    // MARK: - Subscriptions

    static func listSubscriptionGroups(appId: String, repo: any SubscriptionGroupRepository) async throws -> String {
        let cmd = try SubscriptionGroupsList.parse(["--app-id", appId, "--pretty"])
        return try await cmd.execute(repo: repo, affordanceMode: .rest)
    }

    // MARK: - Simulators

    static func listSimulators(repo: any SimulatorRepository) async throws -> String {
        let cmd = try SimulatorsList.parse(["--pretty"])
        return try await cmd.execute(repo: repo, affordanceMode: .rest)
    }

    // MARK: - Code Signing

    static func listCertificates(repo: any CertificateRepository) async throws -> String {
        let cmd = try CertificatesList.parse(["--pretty"])
        return try await cmd.execute(repo: repo, affordanceMode: .rest)
    }

    static func listBundleIDs(repo: any BundleIDRepository) async throws -> String {
        let cmd = try BundleIDsList.parse(["--pretty"])
        return try await cmd.execute(repo: repo, affordanceMode: .rest)
    }

    static func listDevices(repo: any DeviceRepository) async throws -> String {
        let cmd = try DevicesList.parse(["--pretty"])
        return try await cmd.execute(repo: repo, affordanceMode: .rest)
    }

    static func listProfiles(repo: any ProfileRepository) async throws -> String {
        let cmd = try ProfilesList.parse(["--pretty"])
        return try await cmd.execute(repo: repo, affordanceMode: .rest)
    }

    // MARK: - Plugins

    static func listPlugins(repo: any PluginRepository) async throws -> String {
        let cmd = try PluginsList.parse(["--pretty"])
        return try await cmd.execute(repo: repo, affordanceMode: .rest)
    }

    static func listMarketPlugins(repo: any PluginRepository) async throws -> String {
        let cmd = try MarketList.parse(["--pretty"])
        return try await cmd.execute(repo: repo, affordanceMode: .rest)
    }

    // MARK: - App Shots

    static func listTemplates(repo: any TemplateRepository) async throws -> String {
        let cmd = try AppShotsTemplatesList.parse(["--pretty"])
        return try await cmd.execute(repo: repo, affordanceMode: .rest)
    }

    static func listThemes(repo: any ThemeRepository) async throws -> String {
        let cmd = try AppShotsThemesList.parse(["--pretty"])
        return try await cmd.execute(repo: repo, affordanceMode: .rest)
    }

    // MARK: - Territories

    static func listTerritories(repo: any TerritoryRepository) async throws -> String {
        let cmd = try TerritoriesList.parse(["--pretty"])
        return try await cmd.execute(repo: repo, affordanceMode: .rest)
    }
}
