import Foundation
import Testing
@testable import Domain

@Suite
struct BetaAppReviewDetailTests {

    // MARK: - Parent ID

    @Test func `detail carries appId`() {
        let detail = MockRepositoryFactory.makeBetaAppReviewDetail(id: "d-1", appId: "app-42")
        #expect(detail.appId == "app-42")
    }

    // MARK: - Computed Properties

    @Test func `hasContact is true when email and phone present`() {
        let detail = MockRepositoryFactory.makeBetaAppReviewDetail(
            contactPhone: "+1-555-0100",
            contactEmail: "test@example.com"
        )
        #expect(detail.hasContact == true)
    }

    @Test func `hasContact is false when email missing`() {
        let detail = MockRepositoryFactory.makeBetaAppReviewDetail(
            contactPhone: "+1-555-0100",
            contactEmail: nil
        )
        #expect(detail.hasContact == false)
    }

    @Test func `demoAccountConfigured is true when not required`() {
        let detail = MockRepositoryFactory.makeBetaAppReviewDetail(demoAccountRequired: false)
        #expect(detail.demoAccountConfigured == true)
    }

    @Test func `demoAccountConfigured is false when required but missing credentials`() {
        let detail = MockRepositoryFactory.makeBetaAppReviewDetail(
            demoAccountName: nil,
            demoAccountPassword: nil,
            demoAccountRequired: true
        )
        #expect(detail.demoAccountConfigured == false)
    }

    @Test func `demoAccountConfigured is true when required and credentials provided`() {
        let detail = MockRepositoryFactory.makeBetaAppReviewDetail(
            demoAccountName: "demo",
            demoAccountPassword: "pass",
            demoAccountRequired: true
        )
        #expect(detail.demoAccountConfigured == true)
    }

    // MARK: - Affordances

    @Test func `detail affordances include getDetail`() {
        let detail = MockRepositoryFactory.makeBetaAppReviewDetail(id: "d-1", appId: "app-1")
        #expect(detail.affordances["getDetail"] == "asc beta-review detail get --app-id app-1")
    }

    @Test func `detail affordances include updateDetail`() {
        let detail = MockRepositoryFactory.makeBetaAppReviewDetail(id: "d-1")
        #expect(detail.affordances["updateDetail"] == "asc beta-review detail update --detail-id d-1")
    }

    // MARK: - Codable

    @Test func `detail omits nil optional fields from JSON`() throws {
        let detail = MockRepositoryFactory.makeBetaAppReviewDetail(
            contactFirstName: nil,
            contactLastName: nil,
            contactPhone: nil,
            contactEmail: nil,
            demoAccountName: nil,
            demoAccountPassword: nil,
            notes: nil
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(detail)
        let json = String(data: data, encoding: .utf8)!
        #expect(!json.contains("contactFirstName"))
        #expect(!json.contains("contactLastName"))
        #expect(!json.contains("contactPhone"))
        #expect(!json.contains("contactEmail"))
        #expect(!json.contains("demoAccountName"))
        #expect(!json.contains("demoAccountPassword"))
        #expect(!json.contains("notes"))
        // Non-optional fields always present
        #expect(json.contains("demoAccountRequired"))
    }

    @Test func `detail encodes present optional fields`() throws {
        let detail = MockRepositoryFactory.makeBetaAppReviewDetail(
            contactFirstName: "John",
            contactEmail: "john@example.com",
            notes: "Test notes"
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(detail)
        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("contactFirstName"))
        #expect(json.contains("contactEmail"))
        #expect(json.contains("notes"))
    }
}
