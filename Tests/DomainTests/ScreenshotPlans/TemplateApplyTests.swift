import Foundation
import Testing
@testable import Domain

@Suite
struct TemplateApplyTests {

    @Test func `template apply returns HTML with headline`() {
        let template = MockRepositoryFactory.makeScreenshotTemplate(id: "hero", name: "Hero")
        let content = TemplateContent(headline: "Hello World", screenshotFile: "screen.png")
        let html = template.apply(content: content)
        #expect(html.contains("Hello World"))
        #expect(html.contains("<!DOCTYPE html>"))
    }

    @Test func `template apply for viewport returns full-page HTML`() {
        let template = MockRepositoryFactory.makeScreenshotTemplate(id: "hero", name: "Hero")
        let content = TemplateContent(headline: "Test", screenshotFile: "screen.png")
        let html = template.apply(content: content, fillViewport: true)
        #expect(html.contains("width:100%"))
    }

    @Test func `template apply with nil content uses default preview`() {
        let template = MockRepositoryFactory.makeScreenshotTemplate(id: "hero", name: "Hero")
        let html = template.apply()
        #expect(html.contains("<!DOCTYPE html>"))
    }
}
