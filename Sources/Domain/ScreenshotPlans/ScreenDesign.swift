import Foundation

/// A single screen in a screenshot design — rich domain object.
///
/// Knows its template, content, and screenshot. Can render a preview
/// and tell you what actions are available.
///
/// ```
/// let screen = ScreenDesign(index: 0, template: topHero, screenshotFile: "screen.png",
///                           heading: "Ship Faster", subheading: "One command away")
/// screen.previewHTML   // → HTML with real screenshot in template layout
/// screen.isComplete    // → true (has template + heading + screenshot)
/// screen.affordances   // → { generate, changeTemplate, preview }
/// ```
public struct ScreenDesign: Sendable, Equatable, Identifiable {
    public let id: String
    public let index: Int
    /// The template applied to this screen. `nil` = no template yet.
    public let template: ScreenshotTemplate?
    public let screenshotFile: String
    public let heading: String
    public let subheading: String
    // Legacy fields kept for backward compatibility with existing ScreenshotDesign
    public let layoutMode: LayoutMode
    public let visualDirection: String
    public let imagePrompt: String

    /// Rich initializer — with template.
    public init(
        index: Int,
        template: ScreenshotTemplate?,
        screenshotFile: String,
        heading: String,
        subheading: String
    ) {
        self.id = "\(index)"
        self.index = index
        self.template = template
        self.screenshotFile = screenshotFile
        self.heading = heading
        self.subheading = subheading
        self.layoutMode = .center
        self.visualDirection = ""
        self.imagePrompt = ""
    }

    /// Legacy initializer — without template (backward compat).
    public init(
        index: Int,
        screenshotFile: String,
        heading: String,
        subheading: String,
        layoutMode: LayoutMode,
        visualDirection: String,
        imagePrompt: String
    ) {
        self.id = "\(index)"
        self.index = index
        self.template = nil
        self.screenshotFile = screenshotFile
        self.heading = heading
        self.subheading = subheading
        self.layoutMode = layoutMode
        self.visualDirection = visualDirection
        self.imagePrompt = imagePrompt
    }
}

// MARK: - Rich Domain Behavior

extension ScreenDesign {
    /// Whether this screen has everything needed for generation.
    public var isComplete: Bool {
        template != nil && !heading.isEmpty && !screenshotFile.isEmpty
    }

    /// Self-contained HTML preview showing the template with real content.
    /// Returns empty string if no template is set.
    public var previewHTML: String {
        guard let template else { return "" }
        return TemplateHTMLRenderer.renderPage(
            template,
            content: TemplateContent(
                headline: heading,
                subtitle: subheading.isEmpty ? nil : subheading,
                screenshotFile: screenshotFile
            )
        )
    }
}

// MARK: - Affordances

extension ScreenDesign: AffordanceProviding {
    public var affordances: [String: String] {
        var cmds: [String: String] = [
            "changeTemplate": "asc app-shots templates list",
        ]
        if isComplete {
            cmds["generate"] = "asc app-shots generate --design design.json"
            cmds["preview"] = "open preview.html"
        }
        if let template {
            cmds["templateDetail"] = "asc app-shots templates get --id \(template.id)"
        }
        return cmds
    }
}

// MARK: - Codable (template excluded — resolved at runtime)

extension ScreenDesign: Codable {
    private enum CodingKeys: String, CodingKey {
        case index, screenshotFile, heading, subheading, layoutMode, visualDirection, imagePrompt
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let index = try c.decode(Int.self, forKey: .index)
        self.init(
            index: index,
            screenshotFile: try c.decode(String.self, forKey: .screenshotFile),
            heading: try c.decode(String.self, forKey: .heading),
            subheading: try c.decode(String.self, forKey: .subheading),
            layoutMode: try c.decode(LayoutMode.self, forKey: .layoutMode),
            visualDirection: try c.decode(String.self, forKey: .visualDirection),
            imagePrompt: try c.decode(String.self, forKey: .imagePrompt)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(index, forKey: .index)
        try c.encode(screenshotFile, forKey: .screenshotFile)
        try c.encode(heading, forKey: .heading)
        try c.encode(subheading, forKey: .subheading)
        try c.encode(layoutMode, forKey: .layoutMode)
        try c.encode(visualDirection, forKey: .visualDirection)
        try c.encode(imagePrompt, forKey: .imagePrompt)
    }
}
