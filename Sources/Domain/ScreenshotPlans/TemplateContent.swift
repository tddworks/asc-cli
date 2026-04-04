import Foundation

/// User content to render inside a template.
public struct TemplateContent: Sendable, Equatable {
    public let headline: String
    public let subtitle: String?
    public let screenshotFile: String

    public init(headline: String, subtitle: String? = nil, screenshotFile: String) {
        self.headline = headline
        self.subtitle = subtitle
        self.screenshotFile = screenshotFile
    }
}
