import Foundation
import Mockable

/// A provider that supplies sample galleries (gallery templates with sample panel content).
@Mockable
public protocol GalleryTemplateProvider: Sendable {
    var providerId: String { get }
    func galleries() async throws -> [Gallery]
}

/// Repository for querying gallery templates.
@Mockable
public protocol GalleryTemplateRepository: Sendable {
    func listGalleries() async throws -> [Gallery]
    func getGallery(templateId: String) async throws -> Gallery?
}
