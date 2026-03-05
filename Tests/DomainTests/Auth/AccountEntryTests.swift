import Foundation
import Testing
@testable import Domain

@Suite
struct ConnectAccountTests {

    @Test func `connect account id equals name`() {
        let account = ConnectAccount(name: "personal", keyID: "KEY1", issuerID: "ISSUER1", isActive: false)
        #expect(account.id == "personal")
    }

    @Test func `inactive account has use and logout affordances`() {
        let account = ConnectAccount(name: "personal", keyID: "KEY1", issuerID: "ISSUER1", isActive: false)
        #expect(account.affordances["use"] == "asc auth use personal")
        #expect(account.affordances["logout"] == "asc auth logout --name personal")
    }

    @Test func `active account has only logout affordance no use`() {
        let account = ConnectAccount(name: "work", keyID: "KEY2", issuerID: "ISSUER2", isActive: true)
        #expect(account.affordances["use"] == nil)
        #expect(account.affordances["logout"] == "asc auth logout --name work")
    }

    @Test func `connect account encodes to JSON with all fields`() throws {
        let account = ConnectAccount(name: "personal", keyID: "KEY1", issuerID: "ISSUER1", isActive: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(account)
        let json = String(decoding: data, as: UTF8.self)
        #expect(json.contains("\"isActive\":true"))
        #expect(json.contains("\"keyID\":\"KEY1\""))
        #expect(json.contains("\"name\":\"personal\""))
    }
}