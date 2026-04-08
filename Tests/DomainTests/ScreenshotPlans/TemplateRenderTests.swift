import Foundation
import Testing
@testable import Domain

@Suite
struct TemplateRenderTests {

    @Test func `template renderFragment returns inner HTML with content`() {
        let template = MockRepositoryFactory.makeAppShotTemplate(id: "hero", name: "Hero")
        let shot = AppShot(screenshot: "screen.png", type: .feature)
        shot.headline = "Buy Now"
        let html = template.renderFragment(shot: shot)
        #expect(html.contains("Buy Now"))
        #expect(!html.contains("<!DOCTYPE html>"))
    }

    @Test func `themed page wraps body in full HTML`() {
        let page = ThemedPage(body: "<div>styled</div>", width: 1320, height: 2868)
        #expect(page.html.contains("<!DOCTYPE html>"))
        #expect(page.html.contains("<div>styled</div>"))
    }

    @Test func `themed page fillViewport sets 100% dimensions`() {
        let page = ThemedPage(body: "<div>test</div>", width: 1320, height: 2868, fillViewport: true)
        #expect(page.html.contains("width:100%"))
    }

    @Test func `template JSON encoding includes previewHTML`() throws {
        let template = MockRepositoryFactory.makeAppShotTemplate(id: "hero", name: "Hero")
        let data = try JSONEncoder().encode(template)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(json["previewHTML"] as? String != nil)
        #expect((json["previewHTML"] as? String)?.contains("<!DOCTYPE html>") == true)
    }

    @Test func `template JSON encoding includes deviceCount`() throws {
        let template = MockRepositoryFactory.makeAppShotTemplate(id: "hero", name: "Hero")
        let data = try JSONEncoder().encode(template)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(json["deviceCount"] as? Int == 1)
    }
}
