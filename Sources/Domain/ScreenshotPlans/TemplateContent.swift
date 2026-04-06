import Foundation

/// User content to render inside a template.
public struct TemplateContent: Sendable, Equatable {
    public let headline: String
    public let subtitle: String?
    /// Optional tagline override. `nil` uses the template's default tagline.
    public let tagline: String?
    public let screenshotFile: String

    // Style overrides (from AI refine). `nil` uses template defaults.
    public let background: SlideBackground?
    public let textColor: String?

    public init(
        headline: String,
        subtitle: String? = nil,
        tagline: String? = nil,
        screenshotFile: String,
        background: SlideBackground? = nil,
        textColor: String? = nil
    ) {
        self.headline = headline
        self.subtitle = subtitle
        self.tagline = tagline
        self.screenshotFile = screenshotFile
        self.background = background
        self.textColor = textColor
    }
}
