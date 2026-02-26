import Foundation
import Observation

/// Manages the developer's portfolio of App Store Connect apps.
/// Fetches apps and their versions on demand via the `asc` CLI,
/// holds selection state, and orders versions by urgency (CAEOAS pattern).
@Observable
public final class AppPortfolio: @unchecked Sendable {

    // MARK: - State

    public var apps: [ASCApp] = []
    public var versions: [ASCVersion] = []
    public var selectedAppId: String? = nil
    public var isSyncing: Bool = false
    public var lastError: String? = nil
    public var lastSyncDate: Date? = nil

    // MARK: - Private

    private let repository: any AppStoreRepository
    private var backgroundTask: Task<Void, Never>?

    // MARK: - Init

    public init(repository: any AppStoreRepository) {
        self.repository = repository
    }

    // MARK: - Computed

    public var selectedApp: ASCApp? {
        apps.first { $0.id == selectedAppId }
    }

    /// Versions for the selected app, ordered by urgency:
    /// editable (action needed) → pending (in review) → live → everything else.
    public var selectedVersions: [ASCVersion] {
        guard let appId = selectedAppId else { return [] }
        return versions
            .filter { $0.appId == appId }
            .sorted { urgencyScore($0) > urgencyScore($1) }
    }

    /// Most urgent status across all selected app versions (drives the menu bar icon).
    public var overallStatus: AppStatus {
        let active = selectedVersions.filter { $0.appStatus != .removed }
        if active.isEmpty { return .processing }
        if active.contains(where: { $0.appStatus == .editable }) { return .editable }
        if active.contains(where: { $0.appStatus == .pending })  { return .pending }
        if active.contains(where: { $0.appStatus == .live })     { return .live }
        return .processing
    }

    public var lastSyncDescription: String {
        guard let date = lastSyncDate else { return "Never fetched" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Fetched \(formatter.localizedString(for: date, relativeTo: Date()))"
    }

    // MARK: - Operations

    /// Fetches apps list and versions for the selected app.
    public func refresh() async {
        isSyncing = true
        lastError = nil
        defer { isSyncing = false }
        do {
            let fetched = try await repository.fetchApps()
            apps = fetched
            if selectedAppId == nil || !apps.contains(where: { $0.id == selectedAppId }) {
                selectedAppId = apps.first?.id
            }
            if let appId = selectedAppId {
                versions = try await repository.fetchVersions(appId: appId)
            }
            lastSyncDate = Date()
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Switches to a different app and fetches its versions.
    public func selectApp(_ appId: String) {
        guard appId != selectedAppId else { return }
        selectedAppId = appId
        Task {
            isSyncing = true
            defer { isSyncing = false }
            do {
                versions = try await repository.fetchVersions(appId: appId)
                lastSyncDate = Date()
            } catch {
                lastError = error.localizedDescription
            }
        }
    }

    /// Starts periodic background auto-refresh at the given interval.
    public func startAutoRefresh(interval: TimeInterval = 60) {
        backgroundTask?.cancel()
        backgroundTask = Task {
            await refresh()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled else { break }
                await refresh()
            }
        }
    }

    /// Stops periodic background auto-refresh.
    public func stopAutoRefresh() {
        backgroundTask?.cancel()
        backgroundTask = nil
    }

    // MARK: - Helpers

    private func urgencyScore(_ version: ASCVersion) -> Int {
        switch version.appStatus {
        case .editable:   return 3
        case .pending:    return 2
        case .live:       return 1
        case .processing: return 0
        case .removed:    return -1
        }
    }
}
