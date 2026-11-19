import Foundation
import Testing
@testable import ASCKit

@Suite
struct ProjectConfigTests {

    // MARK: - Review contact fields

    @Test func `config without contact fields has no review contact`() {
        let config = ProjectConfig(appId: "app-1", appName: "App", bundleId: "com.example")
        #expect(config.hasReviewContact == false)
        #expect(config.contactFirstName == nil)
        #expect(config.contactLastName == nil)
        #expect(config.contactPhone == nil)
        #expect(config.contactEmail == nil)
    }

    @Test func `config with email and phone has review contact`() {
        let config = ProjectConfig(
            appId: "app-1", appName: "App", bundleId: "com.example",
            contactFirstName: "Jane",
            contactLastName: "Smith",
            contactPhone: "+1-555-0100",
            contactEmail: "jane@example.com"
        )
        #expect(config.hasReviewContact == true)
    }

    @Test func `config with only email has no review contact`() {
        let config = ProjectConfig(
            appId: "app-1", appName: "App", bundleId: "com.example",
            contactEmail: "jane@example.com"
        )
        #expect(config.hasReviewContact == false)
    }

    @Test func `config with only phone has no review contact`() {
        let config = ProjectConfig(
            appId: "app-1", appName: "App", bundleId: "com.example",
            contactPhone: "+1-555-0100"
        )
        #expect(config.hasReviewContact == false)
    }

    // MARK: - Affordances

    @Test func `config with review contact shows updateReviewContact affordance`() {
        let config = ProjectConfig(
            appId: "app-1", appName: "App", bundleId: "com.example",
            contactPhone: "+1-555-0100",
            contactEmail: "jane@example.com"
        )
        #expect(config.affordances["updateReviewContact"] ==
            "asc init --app-id app-1 --contact-email ... --contact-phone ...")
    }

    @Test func `config without review contact shows setReviewContact affordance`() {
        let config = ProjectConfig(appId: "app-1", appName: "App", bundleId: "com.example")
        #expect(config.affordances["setReviewContact"] ==
            "asc init --app-id app-1 --contact-email ... --contact-phone ...")
    }

    // MARK: - Codable (omit nil contact fields)

    @Test func `JSON omits nil contact fields`() throws {
        let config = ProjectConfig(appId: "app-1", appName: "App", bundleId: "com.example")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let json = String(data: try encoder.encode(config), encoding: .utf8)!
        #expect(json == """
        {
          "appId" : "app-1",
          "appName" : "App",
          "bundleId" : "com.example"
        }
        """)
    }

    @Test func `JSON includes contact fields when present`() throws {
        let config = ProjectConfig(
            appId: "app-1", appName: "App", bundleId: "com.example",
            contactFirstName: "Jane",
            contactLastName: "Smith",
            contactPhone: "+1-555-0100",
            contactEmail: "jane@example.com"
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let json = String(data: try encoder.encode(config), encoding: .utf8)!
        #expect(json == """
        {
          "appId" : "app-1",
          "appName" : "App",
          "bundleId" : "com.example",
          "contactEmail" : "jane@example.com",
          "contactFirstName" : "Jane",
          "contactLastName" : "Smith",
          "contactPhone" : "+1-555-0100"
        }
        """)
    }

    @Test func `decoding JSON without contact fields succeeds`() throws {
        let json = """
        {"appId":"app-1","appName":"App","bundleId":"com.example"}
        """
        let config = try JSONDecoder().decode(ProjectConfig.self, from: json.data(using: .utf8)!)
        #expect(config.appId == "app-1")
        #expect(config.contactEmail == nil)
        #expect(config.contactPhone == nil)
    }

    @Test func `decoding JSON with contact fields succeeds`() throws {
        let json = """
        {"appId":"app-1","appName":"App","bundleId":"com.example","contactEmail":"jane@example.com","contactPhone":"+1-555"}
        """
        let config = try JSONDecoder().decode(ProjectConfig.self, from: json.data(using: .utf8)!)
        #expect(config.contactEmail == "jane@example.com")
        #expect(config.contactPhone == "+1-555")
    }
}