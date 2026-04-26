import Foundation
import Testing
@testable import Domain

@Suite
struct SubscriptionGroupLocalizationCodableTests {

    @Test func `roundtrip preserves all fields when present`() throws {
        let loc = SubscriptionGroupLocalization(
            id: "loc-1", groupId: "grp-1", locale: "en-US",
            name: "Premium", customAppName: "Premium App", state: .approved
        )
        let data = try JSONEncoder().encode(loc)
        let decoded = try JSONDecoder().decode(SubscriptionGroupLocalization.self, from: data)
        #expect(decoded == loc)
    }

    @Test func `optional fields are omitted from JSON when nil`() throws {
        let loc = SubscriptionGroupLocalization(id: "loc-1", groupId: "grp-1", locale: "en-US")
        let json = String(decoding: try JSONEncoder().encode(loc), as: UTF8.self)
        #expect(!json.contains("name"))
        #expect(!json.contains("customAppName"))
        #expect(!json.contains("state"))
    }

    @Test func `state raw values match ASC API`() {
        #expect(SubscriptionGroupLocalizationState.prepareForSubmission.rawValue == "PREPARE_FOR_SUBMISSION")
        #expect(SubscriptionGroupLocalizationState.waitingForReview.rawValue == "WAITING_FOR_REVIEW")
        #expect(SubscriptionGroupLocalizationState.approved.rawValue == "APPROVED")
        #expect(SubscriptionGroupLocalizationState.rejected.rawValue == "REJECTED")
    }
}
