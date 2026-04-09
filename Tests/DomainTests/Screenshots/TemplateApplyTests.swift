import Foundation
import Testing
@testable import Domain

@Suite
struct TemplateApplyTests {

    @Test func `template apply returns HTML with headline`() {
        let template = MockRepositoryFactory.makeAppShotTemplate(id: "hero", name: "Hero")
        let shot = AppShot(screenshot: "screen.png", type: .feature)
        shot.headline = "Hello World"
        let html = template.apply(shot: shot)
        #expect(html.contains("Hello World"))
        #expect(html.contains("<!DOCTYPE html>"))
    }

    @Test func `template apply for viewport returns full-page HTML`() {
        let template = MockRepositoryFactory.makeAppShotTemplate(id: "hero", name: "Hero")
        let shot = AppShot(screenshot: "screen.png", type: .feature)
        shot.headline = "Test"
        let html = template.apply(shot: shot, fillViewport: true)
        #expect(html.contains("width:100%"))
    }

    @Test func `template previewHTML uses template name`() {
        let template = MockRepositoryFactory.makeAppShotTemplate(id: "hero", name: "Hero")
        let html = template.previewHTML
        #expect(html.contains("<!DOCTYPE html>"))
        #expect(html.contains("Hero"))
    }
}
