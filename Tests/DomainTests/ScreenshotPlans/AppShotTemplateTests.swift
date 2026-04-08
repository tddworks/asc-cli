import Foundation
import Testing
@testable import Domain

@Suite("AppShotTemplate")
struct AppShotTemplateTests {

    @Test func `template has id, name, and category`() {
        let template = MockRepositoryFactory.makeAppShotTemplate()
        #expect(template.id == "top-hero")
        #expect(template.name == "Top Hero")
        #expect(template.category == .bold)
    }

    @Test func `template reports supported sizes`() {
        let template = MockRepositoryFactory.makeAppShotTemplate(
            supportedSizes: [.portrait, .landscape]
        )
        #expect(template.supportedSizes.contains(.portrait))
        #expect(template.supportedSizes.contains(.landscape))
    }

    @Test func `portrait template is portrait`() {
        let template = MockRepositoryFactory.makeAppShotTemplate(
            supportedSizes: [.portrait]
        )
        #expect(template.isPortrait)
        #expect(!template.isLandscape)
    }

    @Test func `landscape template is landscape`() {
        let template = MockRepositoryFactory.makeAppShotTemplate(
            supportedSizes: [.landscape]
        )
        #expect(!template.isPortrait)
        #expect(template.isLandscape)
    }

    @Test func `template with device has deviceCount 1`() {
        let template = MockRepositoryFactory.makeAppShotTemplate()
        #expect(template.deviceCount == 1)
    }

    @Test func `template without device has deviceCount 0`() {
        let template = MockRepositoryFactory.makeAppShotTemplate(hasDevice: false)
        #expect(template.deviceCount == 0)
    }

    @Test func `template affordances include preview, apply, and list`() {
        let template = MockRepositoryFactory.makeAppShotTemplate(id: "top-hero")
        #expect(template.affordances["apply"] == "asc app-shots templates apply --id top-hero --screenshot screen.png")
        #expect(template.affordances["detail"] == "asc app-shots templates get --id top-hero")
        #expect(template.affordances["listAll"] == "asc app-shots templates list")
        #expect(template.affordances["preview"] == "asc app-shots templates get --id top-hero --preview")
    }

    @Test func `previewHTML contains background and template name`() {
        let template = MockRepositoryFactory.makeAppShotTemplate()
        let html = template.previewHTML
        #expect(html.contains("linear-gradient"))
        #expect(html.contains("Top Hero"))
    }

    @Test func `template is codable`() throws {
        let template = MockRepositoryFactory.makeAppShotTemplate()
        let data = try JSONEncoder().encode(template)
        let decoded = try JSONDecoder().decode(AppShotTemplate.self, from: data)
        #expect(decoded == template)
    }
}
