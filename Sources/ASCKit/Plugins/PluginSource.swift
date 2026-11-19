import Mockable

/// A registry source that provides available plugins.
///
/// Implementations fetch from different registries (GitHub releases, local index, etc.).
/// Returns `[Plugin]` with `isInstalled: false` — the repository cross-references
/// installed status from `PluginLoader`.
@Mockable
public protocol PluginSource: Sendable {
    /// Human-readable source name (e.g. "GitHub: tddworks/asc-registry").
    var name: String { get }

    /// Fetch all available plugins from this source.
    func fetchPlugins() async throws -> [Plugin]
}
