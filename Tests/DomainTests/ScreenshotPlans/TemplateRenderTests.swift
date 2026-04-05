import Foundation
import Testing
@testable import Domain

@Suite
struct TemplateRenderTests {

    // MARK: - renderFragment (inner HTML, no page wrapper)

    @Test func `template renderFragment returns inner HTML with content`() {
        let template = MockRepositoryFactory.makeScreenshotTemplate(id: "hero", name: "Hero")
        let content = TemplateContent(headline: "Buy Now", screenshotFile: "screen.png")
        let html = template.renderFragment(content: content)
        #expect(html.contains("Buy Now"))
        #expect(!html.contains("<!DOCTYPE html>"))
    }

    // MARK: - ThemedPage wraps body in full HTML page

    @Test func `themed page wraps body in full HTML`() {
        let page = ThemedPage(body: "<div>styled</div>", width: 1320, height: 2868)
        #expect(page.html.contains("<!DOCTYPE html>"))
        #expect(page.html.contains("<div>styled</div>"))
    }

    @Test func `themed page fillViewport sets 100% dimensions`() {
        let page = ThemedPage(body: "<div>test</div>", width: 1320, height: 2868, fillViewport: true)
        #expect(page.html.contains("width:100%"))
    }

    // MARK: - Codable includes computed properties

    @Test func `template JSON encoding includes previewHTML`() throws {
        let template = MockRepositoryFactory.makeScreenshotTemplate(id: "hero", name: "Hero")
        let data = try JSONEncoder().encode(template)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(json["previewHTML"] as? String != nil)
        #expect((json["previewHTML"] as? String)?.contains("<!DOCTYPE html>") == true)
    }

    @Test func `template JSON encoding includes deviceCount`() throws {
        let template = MockRepositoryFactory.makeScreenshotTemplate(id: "hero", name: "Hero", deviceCount: 2)
        let data = try JSONEncoder().encode(template)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(json["deviceCount"] as? Int == 2)
    }
}
