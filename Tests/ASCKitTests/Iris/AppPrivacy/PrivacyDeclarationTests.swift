import Foundation
import Testing
@testable import ASCKit

@Suite
struct PrivacyDeclarationTests {
    private func collected(_ category: String, _ purposes: [String], linked: Bool = false, tracking: Bool = false) -> CollectedData {
        CollectedData(category: .init(rawValue: category), purposes: purposes.map(DataPurpose.init(rawValue:)),
                      isLinkedToYou: linked, isUsedToTrackYou: tracking)
    }

    // MARK: - the rows Apple stores (law 1)

    @Test func `should be one not-collected row when no data is collected`() {
        #expect(PrivacyDeclaration.notCollected.entries == [DataUsageEntry(category: nil, purpose: nil, protection: .notCollected)])
    }

    @Test func `should be one row per purpose, linked or not, plus a purpose-less row when the data tracks`() {
        let declaration = PrivacyDeclaration.collected([
            collected("EMAIL_ADDRESS", ["APP_FUNCTIONALITY", "ANALYTICS"], linked: true, tracking: true),
            collected("CRASH_DATA", ["ANALYTICS"]),
        ])

        #expect(declaration.entries == [
            DataUsageEntry(category: .init(rawValue: "EMAIL_ADDRESS"), purpose: .init(rawValue: "APP_FUNCTIONALITY"), protection: .linkedToYou),
            DataUsageEntry(category: .init(rawValue: "EMAIL_ADDRESS"), purpose: .init(rawValue: "ANALYTICS"), protection: .linkedToYou),
            DataUsageEntry(category: .init(rawValue: "EMAIL_ADDRESS"), purpose: nil, protection: .usedToTrackYou),
            DataUsageEntry(category: .init(rawValue: "CRASH_DATA"), purpose: .init(rawValue: "ANALYTICS"), protection: .notLinkedToYou),
        ])
    }

    // MARK: - what asc refuses to send (law 6)

    @Test func `should refuse collected data with no data types`() {
        #expect(throws: AppPrivacyError.noDataTypes) { try PrivacyDeclaration.collected([]).validate() }
    }

    @Test func `should refuse a data type with no purpose`() {
        #expect(throws: AppPrivacyError.noPurposes(category: "CRASH_DATA")) {
            try PrivacyDeclaration.collected([collected("CRASH_DATA", [])]).validate()
        }
    }

    @Test func `should refuse a purpose it doesn't know`() {
        #expect(throws: AppPrivacyError.unknownPurpose("ADS")) {
            try PrivacyDeclaration.collected([collected("CRASH_DATA", ["ADS"])]).validate()
        }
    }

    @Test func `should refuse the same data type declared twice`() {
        #expect(throws: AppPrivacyError.duplicateCategory("CRASH_DATA")) {
            try PrivacyDeclaration.collected([collected("CRASH_DATA", ["ANALYTICS"]), collected("CRASH_DATA", ["APP_FUNCTIONALITY"])]).validate()
        }
    }

    // MARK: - the file and REST body

    @Test func `should read a not-collected declaration from JSON`() throws {
        #expect(try JSONDecoder().decode(PrivacyDeclaration.self, from: Data(#"{"notCollected":true}"#.utf8)) == .notCollected)
    }

    @Test func `should read collected data from JSON in the shape get shows it`() throws {
        let json = #"{"collectedData":[{"category":"CRASH_DATA","purposes":["ANALYTICS"],"isLinkedToYou":false,"isUsedToTrackYou":false}]}"#
        #expect(try JSONDecoder().decode(PrivacyDeclaration.self, from: Data(json.utf8)) == .collected([collected("CRASH_DATA", ["ANALYTICS"])]))
    }

    @Test func `should refuse JSON that says both not collected and what is collected`() {
        let json = #"{"notCollected":true,"collectedData":[{"category":"CRASH_DATA","purposes":["ANALYTICS"],"isLinkedToYou":false,"isUsedToTrackYou":false}]}"#
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(PrivacyDeclaration.self, from: Data(json.utf8)) }
    }
}
