import Domain
import Foundation

/// Shared handler logic for REST API endpoints.
/// Each method takes an injected repository, calls the domain layer directly,
/// and formats the response using OutputFormatter in REST mode.
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
        let response = try await repo.listApps(limit: limit)
        return try formatter.formatAgentItems(
            response.data,
            headers: [],
            rowMapper: { _ in [] },
            affordanceMode: .rest
        )
    }

    static func getApp(id: String, repo: any AppRepository) async throws -> String {
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
        let versions = try await repo.listVersions(appId: appId)
        return try formatter.formatAgentItems(
            versions,
            headers: [],
            rowMapper: { _ in [] },
            affordanceMode: .rest
        )
    }

    // MARK: - Builds

    static func listBuilds(appId: String, repo: any BuildRepository) async throws -> String {
        let response = try await repo.listBuilds(appId: appId, platform: nil, version: nil, limit: nil)
        return try formatter.formatAgentItems(
            response.data,
            headers: [],
            rowMapper: { _ in [] },
            affordanceMode: .rest
        )
    }

    // MARK: - TestFlight

    static func listBetaGroups(appId: String, repo: any TestFlightRepository) async throws -> String {
        let response = try await repo.listBetaGroups(appId: appId, limit: nil)
        return try formatter.formatAgentItems(
            response.data,
            headers: [],
            rowMapper: { _ in [] },
            affordanceMode: .rest
        )
    }

    // MARK: - Simulators

    static func listSimulators(repo: any SimulatorRepository) async throws -> String {
        let simulators = try await repo.listSimulators(filter: .all)
        return try formatter.formatAgentItems(
            simulators,
            headers: [],
            rowMapper: { _ in [] },
            affordanceMode: .rest
        )
    }

    // MARK: - Code Signing

    static func listCertificates(repo: any CertificateRepository) async throws -> String {
        let certs = try await repo.listCertificates(certificateType: nil)
        return try formatter.formatAgentItems(
            certs,
            headers: [],
            rowMapper: { _ in [] },
            affordanceMode: .rest
        )
    }

    static func listBundleIDs(repo: any BundleIDRepository) async throws -> String {
        let ids = try await repo.listBundleIDs(platform: nil, identifier: nil)
        return try formatter.formatAgentItems(
            ids,
            headers: [],
            rowMapper: { _ in [] },
            affordanceMode: .rest
        )
    }

    static func listDevices(repo: any DeviceRepository) async throws -> String {
        let devices = try await repo.listDevices(platform: nil)
        return try formatter.formatAgentItems(
            devices,
            headers: [],
            rowMapper: { _ in [] },
            affordanceMode: .rest
        )
    }

    static func listProfiles(repo: any ProfileRepository) async throws -> String {
        let profiles = try await repo.listProfiles(bundleIdId: nil, profileType: nil)
        return try formatter.formatAgentItems(
            profiles,
            headers: [],
            rowMapper: { _ in [] },
            affordanceMode: .rest
        )
    }

    // MARK: - Plugins

    static func listPlugins(repo: any PluginRepository) async throws -> String {
        let plugins = try await repo.listInstalled()
        return try formatter.formatAgentItems(
            plugins,
            headers: [],
            rowMapper: { _ in [] },
            affordanceMode: .rest
        )
    }

    static func listMarketPlugins(repo: any PluginRepository) async throws -> String {
        let plugins = try await repo.listAvailable()
        return try formatter.formatAgentItems(
            plugins,
            headers: [],
            rowMapper: { _ in [] },
            affordanceMode: .rest
        )
    }

    // MARK: - Reviews

    static func listReviews(appId: String, repo: any CustomerReviewRepository) async throws -> String {
        let reviews = try await repo.listReviews(appId: appId)
        return try formatter.formatAgentItems(
            reviews,
            headers: [],
            rowMapper: { _ in [] },
            affordanceMode: .rest
        )
    }

    // MARK: - IAP

    static func listIAP(appId: String, repo: any InAppPurchaseRepository) async throws -> String {
        let iaps = try await repo.listInAppPurchases(appId: appId, limit: nil)
        return try formatter.formatAgentItems(
            iaps.data,
            headers: [],
            rowMapper: { _ in [] },
            affordanceMode: .rest
        )
    }

    // MARK: - Subscriptions

    static func listSubscriptionGroups(appId: String, repo: any SubscriptionGroupRepository) async throws -> String {
        let response = try await repo.listSubscriptionGroups(appId: appId, limit: nil)
        return try formatter.formatAgentItems(
            response.data,
            headers: [],
            rowMapper: { _ in [] },
            affordanceMode: .rest
        )
    }

    // MARK: - App Shots

    static func listTemplates(repo: any TemplateRepository) async throws -> String {
        let templates = try await repo.listTemplates(size: nil)
        return try formatter.formatAgentItems(
            templates,
            headers: [],
            rowMapper: { _ in [] },
            affordanceMode: .rest
        )
    }

    static func listThemes(repo: any ThemeRepository) async throws -> String {
        let themes = try await repo.listThemes()
        return try formatter.formatAgentItems(
            themes,
            headers: [],
            rowMapper: { _ in [] },
            affordanceMode: .rest
        )
    }

    // MARK: - Territories

    static func listTerritories(repo: any TerritoryRepository) async throws -> String {
        let territories = try await repo.listTerritories()
        return try formatter.formatAgentItems(
            territories,
            headers: [],
            rowMapper: { _ in [] },
            affordanceMode: .rest
        )
    }
}
