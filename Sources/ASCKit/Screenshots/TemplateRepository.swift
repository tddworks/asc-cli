import Foundation
import Mockable

/// A provider that supplies screenshot templates.
///
/// Plugins register providers to contribute their templates to the platform.
/// For example, Blitz registers a provider with 23 built-in templates.
@Mockable
public protocol TemplateProvider: Sendable {
    /// The unique identifier for this provider (e.g. "blitz", "custom").
    var providerId: String { get }

    /// Return all templates this provider offers.
    func templates() async throws -> [AppShotTemplate]
}

/// Repository for querying screenshot templates.
///
/// The platform ships with no built-in templates. Plugins register
/// `TemplateProvider` implementations to supply templates.
@Mockable
public protocol TemplateRepository: Sendable {
    /// List all templates from all providers, optionally filtered by screen size.
    func listTemplates(size: ScreenSize?) async throws -> [AppShotTemplate]

    /// Get a specific template by ID (searches all providers).
    func getTemplate(id: String) async throws -> AppShotTemplate?
}
