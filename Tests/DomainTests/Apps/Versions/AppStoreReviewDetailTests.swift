import Foundation
import Testing
@testable import Domain

@Suite
struct AppStoreReviewDetailTests {

    @Test func `hasContact is true when both email and phone are set`() {
        let detail = MockRepositoryFactory.makeReviewDetail(
            contactPhone: "+1-555-0100",
            contactEmail: "dev@example.com"
        )
        #expect(detail.hasContact == true)
    }

    @Test func `hasContact is false when email is missing`() {
        let detail = MockRepositoryFactory.makeReviewDetail(
            contactPhone: "+1-555-0100",
            contactEmail: nil
        )
        #expect(detail.hasContact == false)
    }

    @Test func `hasContact is false when phone is missing`() {
        let detail = MockRepositoryFactory.makeReviewDetail(
            contactPhone: nil,
            contactEmail: "dev@example.com"
        )
        #expect(detail.hasContact == false)
    }

    @Test func `demoAccountConfigured is true when demo not required`() {
        let detail = MockRepositoryFactory.makeReviewDetail(
            demoAccountRequired: false,
            demoAccountName: nil,
            demoAccountPassword: nil
        )
        #expect(detail.demoAccountConfigured == true)
    }

    @Test func `demoAccountConfigured is true when required and credentials provided`() {
        let detail = MockRepositoryFactory.makeReviewDetail(
            demoAccountRequired: true,
            demoAccountName: "demo_user",
            demoAccountPassword: "secret"
        )
        #expect(detail.demoAccountConfigured == true)
    }

    @Test func `demoAccountConfigured is false when required but credentials missing`() {
        let detail = MockRepositoryFactory.makeReviewDetail(
            demoAccountRequired: true,
            demoAccountName: nil,
            demoAccountPassword: nil
        )
        #expect(detail.demoAccountConfigured == false)
    }

    @Test func `review detail codable round-trip preserves all fields`() throws {
        let detail = MockRepositoryFactory.makeReviewDetail(
            id: "rd-rt",
            versionId: "v-rt",
            contactFirstName: "Jane",
            contactLastName: "Smith",
            contactPhone: "+44-20-7946-0958",
            contactEmail: "jane@example.com",
            demoAccountRequired: true,
            demoAccountName: "demo",
            demoAccountPassword: "pass"
        )
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(detail)
        let decoded = try decoder.decode(AppStoreReviewDetail.self, from: data)
        #expect(decoded == detail)
    }

    @Test func `review detail nil fields omitted from JSON`() throws {
        let detail = AppStoreReviewDetail(
            id: "rd-1",
            versionId: "v-1",
            demoAccountRequired: false
        )
        let data = try JSONEncoder().encode(detail)
        let json = String(data: data, encoding: .utf8)!
        #expect(!json.contains("contactFirstName"))
        #expect(!json.contains("contactEmail"))
        #expect(!json.contains("demoAccountName"))
        #expect(!json.contains("notes"))
    }

    @Test func `review detail affordances include get and update commands`() {
        let detail = MockRepositoryFactory.makeReviewDetail(id: "rd-1", versionId: "v-42")
        #expect(detail.affordances["getReviewDetail"] == "asc version-review-detail get --version-id v-42")
        #expect(detail.affordances["updateReviewDetail"] == "asc version-review-detail update --version-id v-42")
    }

    @Test func `notes field round-trips through Codable`() throws {
        let detail = MockRepositoryFactory.makeReviewDetail(notes: "Please use the staging environment")
        let data = try JSONEncoder().encode(detail)
        let decoded = try JSONDecoder().decode(AppStoreReviewDetail.self, from: data)
        #expect(decoded.notes == "Please use the staging environment")
    }
}
