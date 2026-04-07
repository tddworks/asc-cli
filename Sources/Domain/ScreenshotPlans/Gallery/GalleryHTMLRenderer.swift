import Foundation

/// Renders gallery panels as HTML matching the gallery-templates-poc structure.
///
/// Uses `cqi` units + `container-type:inline-size` for responsive scaling.
/// Panel aspect ratio: 1320/2868 (iPhone App Store screenshot).
public enum GalleryHTMLRenderer {

    /// Render a single AppShot as an inner panel HTML fragment.
    ///
    /// This is the `.pi` div contents — background + text + device.
    /// The caller wraps it in a panel container.
    public static func renderPanel(
        _ shot: AppShot,
        screenTemplate: ScreenTemplate,
        palette: GalleryPalette
    ) -> String {
        let bg = palette.background

        // Text — headline positioned absolute with cqi units
        let hl = screenTemplate.headline
        let hlSize = fmt(hl.size * 100)
        let hlTop = fmt(hl.y * 100)
        let hlText = (shot.headline ?? "").replacingOccurrences(of: "\n", with: "<br>")

        var textHTML = ""
        textHTML += "<div style=\"position:absolute;top:\(hlTop)%;left:5%;right:5%;z-index:4;"
        textHTML += "font-weight:\(hl.weight);font-size:\(hlSize)cqi;"
        textHTML += "color:#000;line-height:0.92;letter-spacing:-0.03em;"
        textHTML += "text-align:\(hl.align);white-space:pre-line\">"
        textHTML += "\(hlText)</div>"

        // Device — iPhone frame with screenshot
        var devHTML = ""
        if let dev = screenTemplate.device {
            let dw = fmt(dev.width * 100)
            let dl = fmt((dev.x - dev.width / 2) * 100)
            let dt = fmt(dev.y * 100)

            devHTML += "<div class=\"dw\" style=\"left:\(dl)%;top:\(dt)%;width:\(dw)%\">"
            devHTML += "<div class=\"df\">"
            devHTML += "<div class=\"ds\"><img src=\"\(shot.screenshot)\" alt=\"\"></div>"
            if let frameURL = phoneFrameDataURL {
                devHTML += "<img class=\"dfi\" src=\"\(frameURL)\" alt=\"\">"
            }
            devHTML += "</div></div>"
        }

        return "<div class=\"pi\" style=\"background:\(bg);\">"
            + "\(textHTML)\(devHTML)"
            + "</div>"
    }

    // MARK: - Preview

    /// Render a full HTML preview page for a gallery template — same wireframe phone
    /// as the single template previews. Used in the template browser UI.
    public static func renderPreviewPage(_ name: String, screenTemplate: ScreenTemplate) -> String {
        // Convert gallery ScreenTemplate → ScreenshotTemplate to reuse TemplateHTMLRenderer
        let hl = screenTemplate.headline
        let textSlots = [
            TemplateTextSlot(
                role: .heading,
                preview: name,
                x: hl.align == "left" ? 0.06 : 0.5,
                y: hl.y,
                fontSize: hl.size,
                fontWeight: hl.weight,
                color: "#FFFFFF",
                textAlign: hl.align
            )
        ]
        let deviceSlots: [TemplateDeviceSlot]
        if let dev = screenTemplate.device {
            deviceSlots = [TemplateDeviceSlot(x: dev.x, y: dev.y, scale: dev.width)]
        } else {
            deviceSlots = []
        }
        let template = ScreenshotTemplate(
            id: "gallery-preview",
            name: name,
            category: .custom,
            supportedSizes: [.portrait],
            description: "",
            background: .gradient(from: "#1a1d26", to: "#2a2d38", angle: 180),
            textSlots: textSlots,
            deviceSlots: deviceSlots
        )
        return template.previewHTML
    }

    // MARK: - Helpers

    /// Base64 data URL of the iPhone frame PNG. Set by infrastructure at startup.
    nonisolated(unsafe) public static var phoneFrameDataURL: String?

    private static func fmt(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}
