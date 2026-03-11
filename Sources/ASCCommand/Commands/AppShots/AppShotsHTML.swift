import ArgumentParser
import CoreGraphics
import Domain
import Foundation
import ImageIO

struct AppShotsHTML: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "html",
        abstract: "Generate a self-contained HTML page for App Store screenshots — no AI needed"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Path to plan.json (default: .asc/app-shots/app-shots-plan.json)")
    var plan: String = ".asc/app-shots/app-shots-plan.json"

    @Option(name: .long, help: "Directory to write the HTML file (default: .asc/app-shots/output)")
    var outputDir: String = ".asc/app-shots/output"

    @Option(name: .long, help: "Output image width in pixels (default: 1320 — iPhone 6.9\")")
    var outputWidth: Int = 1320

    @Option(name: .long, help: "Output image height in pixels (default: 2868 — iPhone 6.9\")")
    var outputHeight: Int = 2868

    @Option(name: .long, help: "Named device type — overrides --output-width/height")
    var deviceType: AppShotsDisplayType?

    @Option(name: .long, help: "Device mockup: a file path, a device name from mockups.json, or \"none\" to disable. Default: bundled iPhone 17 Pro Max frame.")
    var mockup: String?

    @Option(name: .long, help: "Screen area X inset in pixels from mockup edge (overrides mockups.json value)")
    var screenInsetX: Int?

    @Option(name: .long, help: "Screen area Y inset in pixels from mockup edge (overrides mockups.json value)")
    var screenInsetY: Int?

    @Argument(help: "Screenshot files — omit to auto-discover *.png/*.jpg from the plan's directory")
    var screenshots: [String] = []

    func run() async throws {
        print(try await execute())
    }

    func execute() async throws -> String {
        let effectiveWidth = deviceType.map { $0.dimensions.width } ?? outputWidth
        let effectiveHeight = deviceType.map { $0.dimensions.height } ?? outputHeight

        // Load plan
        let planURL = URL(fileURLWithPath: plan)
        let planData = try Data(contentsOf: planURL)
        let loadedPlan = try JSONDecoder().decode(ScreenPlan.self, from: planData)

        // Resolve screenshots
        let resolvedScreenshots: [String]
        if screenshots.isEmpty {
            let planDir = planURL.deletingLastPathComponent()
            let contents = (try? FileManager.default.contentsOfDirectory(at: planDir, includingPropertiesForKeys: nil)) ?? []
            resolvedScreenshots = contents
                .filter { ["png", "jpg", "jpeg"].contains($0.pathExtension.lowercased()) }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }
                .map { $0.path }
        } else {
            resolvedScreenshots = screenshots
        }

        // Build screenshot data map: filename → base64 data URI
        var screenshotDataURIs: [String: String] = [:]
        for path in resolvedScreenshots {
            let url = URL(fileURLWithPath: path)
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw ValidationError("Screenshot file not found: \(path)")
            }
            let data = try Data(contentsOf: url)
            let ext = url.pathExtension.lowercased()
            let mime = ext == "jpg" || ext == "jpeg" ? "image/jpeg" : "image/png"
            screenshotDataURIs[url.lastPathComponent] = "data:\(mime);base64,\(data.base64EncodedString())"
        }

        // Resolve mockup frame (default: bundled iPhone 17 Pro Max)
        let mockupInfo = try resolveMockupInfo()

        // Generate HTML
        let html = generateHTML(
            plan: loadedPlan,
            screenshotDataURIs: screenshotDataURIs,
            mockupInfo: mockupInfo,
            width: effectiveWidth,
            height: effectiveHeight
        )

        // Write output
        let outputDirURL = URL(fileURLWithPath: outputDir)
        try FileManager.default.createDirectory(at: outputDirURL, withIntermediateDirectories: true)
        let htmlPath = outputDirURL.appendingPathComponent("app-shots.html")
        try html.write(to: htmlPath, atomically: true, encoding: .utf8)

        return formatOutput(path: htmlPath.path)
    }

    /// Mockup frame data for HTML embedding.
    struct MockupInfo {
        let dataURI: String
        let frameWidth: Int
        let frameHeight: Int
        let insetX: Int
        let insetY: Int
    }

    private func resolveMockupInfo() throws -> MockupInfo? {
        let resolved = try MockupResolver.resolve(
            argument: mockup,
            insetXOverride: screenInsetX,
            insetYOverride: screenInsetY
        )
        guard let r = resolved else { return nil }

        let data = try Data(contentsOf: r.fileURL)
        let dataURI = "data:image/png;base64,\(data.base64EncodedString())"

        return MockupInfo(
            dataURI: dataURI,
            frameWidth: r.frameWidth,
            frameHeight: r.frameHeight,
            insetX: r.screenInsetX,
            insetY: r.screenInsetY
        )
    }

    private func formatOutput(path: String) -> String {
        switch globals.outputFormat {
        case .table:
            return "| File |\n|------|\n| \(path) |"
        case .markdown:
            return "## Generated HTML\n\n- `\(path)`"
        default:
            return "{\"file\":\"\(path)\"}"
        }
    }

    // MARK: - HTML Generation

    private func generateHTML(
        plan: ScreenPlan,
        screenshotDataURIs: [String: String],
        mockupInfo: MockupInfo?,
        width: Int,
        height: Int
    ) -> String {
        let screenshotCards = plan.screens.map { screen in
            let dataURI = matchScreenshot(screen: screen, dataURIs: screenshotDataURIs)
            return renderScreenCard(screen: screen, dataURI: dataURI, mockupInfo: mockupInfo, plan: plan, width: width, height: height)
        }.joined(separator: "\n")

        let aspectRatio = Double(width) / Double(height)
        let previewW = 320
        let previewH = Int(Double(previewW) / aspectRatio)

        // Mockup-aware device CSS
        let deviceCSS: String
        if let m = mockupInfo {
            let screenW = m.frameWidth - 2 * m.insetX
            let screenH = m.frameHeight - 2 * m.insetY
            let insetXPct = Double(m.insetX) / Double(m.frameWidth) * 100
            let insetYPct = Double(m.insetY) / Double(m.frameHeight) * 100
            let screenWPct = Double(screenW) / Double(m.frameWidth) * 100
            let screenHPct = Double(screenH) / Double(m.frameHeight) * 100
            let borderRadiusPct = 13.8
            deviceCSS = """
            .slide .phone .device {
                position: relative;
            }
            .slide .phone .device .mockup-frame {
                display: block;
                width: 100%;
                height: auto;
                position: relative;
                z-index: 2;
                pointer-events: none;
            }
            .slide .phone .device .screen-content {
                position: absolute;
                left: \(String(format: "%.2f", insetXPct))%;
                top: \(String(format: "%.2f", insetYPct))%;
                width: \(String(format: "%.2f", screenWPct))%;
                height: \(String(format: "%.2f", screenHPct))%;
                z-index: 1;
                border-radius: \(String(format: "%.1f", borderRadiusPct))% / \(String(format: "%.1f", borderRadiusPct * Double(m.frameWidth) / Double(m.frameHeight)))%;
                overflow: hidden;
            }
            .slide .phone .device .screen-content img {
                display: block;
                width: 100%;
                height: 100%;
                object-fit: cover;
            }
            """
        } else {
            deviceCSS = """
            .slide .phone .device {
                position: relative;
                border-radius: \(Int(Double(width) * 0.06))px;
                overflow: hidden;
                box-shadow: 0 \(width / 20)px \(width / 8)px rgba(0,0,0,0.4);
            }
            .slide .phone .device img {
                display: block;
                width: 100%;
                height: 100%;
                object-fit: cover;
            }
            """
        }

        // Device size picker entries
        let sizes: [(label: String, w: Int, h: Int)] = [
            ("6.9\"", 1320, 2868),
            ("6.7\"", 1290, 2796),
            ("6.5\"", 1260, 2736),
            ("6.3\"", 1206, 2622),
            ("6.1\"", 1179, 2556),
        ]

        let sizeButtons = sizes.map { size in
            let isActive = size.w == width && size.h == height
            return "<button class=\"size-btn\(isActive ? " active" : "")\" data-w=\"\(size.w)\" data-h=\"\(size.h)\">\(size.label)</button>"
        }.joined(separator: "\n            ")

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>\(escapeHTML(plan.appName)) — App Store Screenshots</title>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/html-to-image/1.11.11/html-to-image.min.js"></script>
        <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&display=swap');

        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Helvetica Neue', sans-serif;
            background: #111;
            color: #e0e0e0;
            min-height: 100vh;
        }

        /* ── Header bar ── */
        .header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 20px 40px;
            border-bottom: 1px solid rgba(255,255,255,0.06);
        }

        .header-left h1 {
            font-size: 18px;
            font-weight: 700;
            color: #fff;
        }

        .header-left .meta {
            font-size: 13px;
            color: #666;
            margin-top: 2px;
        }

        .header-right {
            display: flex;
            align-items: center;
            gap: 6px;
        }

        .size-btn {
            background: rgba(255,255,255,0.08);
            color: #888;
            border: none;
            padding: 8px 14px;
            border-radius: 8px;
            font-size: 13px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.15s;
        }

        .size-btn:hover { background: rgba(255,255,255,0.12); color: #ccc; }
        .size-btn.active {
            background: \(plan.colors.accent);
            color: #fff;
        }

        .export-all-btn {
            background: \(plan.colors.accent);
            color: #fff;
            border: none;
            padding: 8px 24px;
            border-radius: 8px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            margin-left: 10px;
            transition: opacity 0.15s;
        }

        .export-all-btn:hover { opacity: 0.85; }
        .export-all-btn:disabled { opacity: 0.4; cursor: not-allowed; }

        /* ── Grid ── */
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(\(previewW)px, 1fr));
            gap: 20px;
            padding: 32px 40px;
            max-width: 1600px;
            margin: 0 auto;
        }

        .card {
            display: flex;
            flex-direction: column;
        }

        /* Preview container — scales the full-res slide to a card */
        .preview-wrap {
            width: 100%;
            aspect-ratio: \(width) / \(height);
            overflow: hidden;
            border-radius: \(Int(Double(width) * 0.04))px;
            position: relative;
            cursor: pointer;
            transition: transform 0.2s, box-shadow 0.2s;
        }

        .preview-wrap:hover {
            transform: translateY(-4px);
            box-shadow: 0 12px 40px rgba(0,0,0,0.5);
        }

        .preview-wrap .slide {
            transform-origin: top left;
        }

        .card-footer {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 10px 4px 0;
        }

        .card-footer .card-label {
            font-size: 13px;
            color: #666;
            font-weight: 500;
        }

        .card-footer .card-index {
            font-size: 13px;
            color: #444;
            font-weight: 600;
        }

        /* ── Full-resolution slide ── */
        .slide {
            width: \(width)px;
            height: \(height)px;
            position: relative;
            overflow: hidden;
            border-radius: \(Int(Double(width) * 0.04))px;
        }

        .slide .caption {
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            z-index: 2;
            padding: \(Int(Double(height) * 0.04))px \(Int(Double(width) * 0.065))px 0;
        }

        .slide .caption h2 {
            font-weight: 800;
            font-size: \(Int(Double(width) * 0.1))px;
            line-height: 1.0;
            letter-spacing: -0.03em;
        }

        .slide .caption p {
            font-weight: 400;
            font-size: \(Int(Double(width) * 0.035))px;
            line-height: 1.3;
            margin-top: \(Int(Double(height) * 0.008))px;
            opacity: 0.65;
        }

        .slide .phone {
            position: absolute;
            z-index: 1;
        }

        \(deviceCSS)

        /* Layout: center — phone centered, overflows bottom */
        .layout-center .phone {
            bottom: \(Int(Double(height) * -0.14))px;
            left: 50%;
            transform: translateX(-50%);
            width: \(Int(Double(width) * 0.85))px;
        }

        .layout-center .phone .device { width: 100%; }

        .layout-center .caption {
            padding-top: \(Int(Double(height) * 0.035))px;
            text-align: center;
        }

        /* Layout: tilted — hero, slight rotation, overflows bottom */
        .layout-tilted .phone {
            bottom: \(Int(Double(height) * -0.12))px;
            left: 50%;
            transform: translateX(-50%) rotate(-4deg);
            width: \(Int(Double(width) * 0.88))px;
        }

        .layout-tilted .phone .device { width: 100%; }

        .layout-tilted .caption {
            padding-top: \(Int(Double(height) * 0.035))px;
        }

        /* Layout: left — text left, phone right, overflows bottom+right */
        .layout-left .caption {
            width: 55%;
            padding-top: \(Int(Double(height) * 0.06))px;
        }

        .layout-left .phone {
            right: \(Int(Double(width) * -0.06))px;
            bottom: \(Int(Double(height) * -0.14))px;
            width: \(Int(Double(width) * 0.62))px;
        }

        .layout-left .phone .device { width: 100%; }

        /* ── Off-screen export container ── */
        .export-container {
            position: absolute;
            left: -99999px;
            top: 0;
        }

        .status-bar {
            position: fixed;
            bottom: 0;
            left: 0;
            right: 0;
            background: rgba(17,17,17,0.95);
            backdrop-filter: blur(10px);
            border-top: 1px solid rgba(255,255,255,0.06);
            padding: 12px 40px;
            text-align: center;
            font-size: 13px;
            color: #888;
            transform: translateY(100%);
            transition: transform 0.3s;
            z-index: 100;
        }

        .status-bar.visible { transform: translateY(0); }
        </style>
        </head>
        <body>
        <div class="header">
            <div class="header-left">
                <h1>\(escapeHTML(plan.appName))</h1>
                <div class="meta">\(plan.screens.count) screenshots &middot; \(width)&times;\(height)</div>
            </div>
            <div class="header-right">
                \(sizeButtons)
                <button class="export-all-btn" onclick="exportAll()">Export All</button>
            </div>
        </div>

        <div class="grid">
        \(screenshotCards)
        </div>

        <div class="status-bar" id="statusBar"></div>

        <!-- Off-screen full-resolution slides for export -->
        <div class="export-container" id="exportContainer">
        \(plan.screens.map { screen in
            let dataURI = matchScreenshot(screen: screen, dataURIs: screenshotDataURIs)
            return renderExportSlide(screen: screen, dataURI: dataURI, mockupInfo: mockupInfo, plan: plan, width: width, height: height)
        }.joined(separator: "\n"))
        </div>

        <script>
        const W = \(width);
        const H = \(height);

        // Scale previews to fit their containers
        function scaleAllPreviews() {
            document.querySelectorAll('.preview-wrap').forEach(wrap => {
                const slide = wrap.querySelector('.slide');
                if (!slide) return;
                const scale = wrap.offsetWidth / W;
                slide.style.transform = 'scale(' + scale + ')';
            });
        }
        scaleAllPreviews();
        window.addEventListener('resize', scaleAllPreviews);

        // Size picker (visual only — shows which size is selected; actual re-gen requires CLI)
        document.querySelectorAll('.size-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                document.querySelectorAll('.size-btn').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
            });
        });

        function showStatus(msg) {
            const bar = document.getElementById('statusBar');
            bar.textContent = msg;
            bar.classList.add('visible');
        }
        function hideStatus() {
            document.getElementById('statusBar').classList.remove('visible');
        }

        async function exportSingle(index) {
            const el = document.getElementById('export-slide-' + index);
            if (!el) return;

            const container = document.getElementById('exportContainer');
            container.style.left = '0px';
            container.style.opacity = '0';
            container.style.zIndex = '-1';

            await htmlToImage.toPng(el, { width: W, height: H, pixelRatio: 1, cacheBust: true });
            const dataUrl = await htmlToImage.toPng(el, { width: W, height: H, pixelRatio: 1, cacheBust: true });

            container.style.left = '-99999px';

            const link = document.createElement('a');
            link.download = 'screen-' + index + '-' + W + 'x' + H + '.png';
            link.href = dataUrl;
            link.click();
        }

        async function exportAll() {
            const btn = document.querySelector('.export-all-btn');
            btn.disabled = true;

            const indices = [\(plan.screens.map { "\($0.index)" }.joined(separator: ", "))];
            for (let i = 0; i < indices.length; i++) {
                showStatus('Exporting screen ' + (i + 1) + ' of ' + indices.length + '...');
                await exportSingle(indices[i]);
                await new Promise(r => setTimeout(r, 300));
            }

            showStatus('All ' + indices.length + ' screenshots exported!');
            btn.disabled = false;
            setTimeout(hideStatus, 3000);
        }
        </script>
        </body>
        </html>
        """
    }

    private func renderDeviceHTML(dataURI: String?, mockupInfo: MockupInfo?, plan: ScreenPlan, screenIndex: Int) -> String {
        if let m = mockupInfo {
            let screenshotTag: String
            if let uri = dataURI {
                screenshotTag = "<img src=\"\(uri)\" alt=\"Screen \(screenIndex)\">"
            } else {
                screenshotTag = "<div style=\"width:100%;height:100%;background:\(plan.colors.accent);opacity:0.3;\"></div>"
            }
            return """
            <div class="device">
                <div class="screen-content">\(screenshotTag)</div>
                <img class="mockup-frame" src="\(m.dataURI)" alt="Device frame">
            </div>
            """
        } else {
            if let uri = dataURI {
                return """
                <div class="device"><img src="\(uri)" alt="Screen \(screenIndex)"></div>
                """
            } else {
                return """
                <div class="device"><div style="width:100%;height:100%;background:\(plan.colors.accent);opacity:0.3;"></div></div>
                """
            }
        }
    }

    private func renderScreenCard(
        screen: ScreenConfig,
        dataURI: String?,
        mockupInfo: MockupInfo?,
        plan: ScreenPlan,
        width: Int,
        height: Int
    ) -> String {
        let deviceHTML = renderDeviceHTML(dataURI: dataURI, mockupInfo: mockupInfo, plan: plan, screenIndex: screen.index)
        let label = screen.index == 0 ? "Hero" : screen.heading

        return """
        <div class="card">
            <div class="preview-wrap" onclick="exportSingle(\(screen.index))">
                <div class="slide layout-\(screen.layoutMode.rawValue)" style="background:\(plan.colors.primary);">
                    <div class="caption">
                        <h2 style="color:\(plan.colors.text);">\(escapeHTML(screen.heading))</h2>
                        <p style="color:\(plan.colors.subtext);">\(escapeHTML(screen.subheading))</p>
                    </div>
                    <div class="phone">
                        \(deviceHTML)
                    </div>
                </div>
            </div>
            <div class="card-footer">
                <span class="card-label">\(escapeHTML(label))</span>
                <span class="card-index">#\(screen.index)</span>
            </div>
        </div>
        """
    }

    private func renderExportSlide(
        screen: ScreenConfig,
        dataURI: String?,
        mockupInfo: MockupInfo?,
        plan: ScreenPlan,
        width: Int,
        height: Int
    ) -> String {
        let deviceHTML = renderDeviceHTML(dataURI: dataURI, mockupInfo: mockupInfo, plan: plan, screenIndex: screen.index)

        return """
        <div id="export-slide-\(screen.index)" class="slide layout-\(screen.layoutMode.rawValue)" style="background:\(plan.colors.primary);">
            <div class="caption">
                <h2 style="color:\(plan.colors.text);">\(escapeHTML(screen.heading))</h2>
                <p style="color:\(plan.colors.subtext);">\(escapeHTML(screen.subheading))</p>
            </div>
            <div class="phone">
                \(deviceHTML)
            </div>
        </div>
        """
    }

    private func matchScreenshot(screen: ScreenConfig, dataURIs: [String: String]) -> String? {
        if let uri = dataURIs[screen.screenshotFile] {
            return uri
        }
        let sorted = dataURIs.keys.sorted()
        if screen.index < sorted.count {
            return dataURIs[sorted[screen.index]]
        }
        return nil
    }

    private func escapeHTML(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
