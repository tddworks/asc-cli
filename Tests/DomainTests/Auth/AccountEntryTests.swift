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

    @Test func `should leave the issuer ID out of the JSON when the account is an individual key`() throws {
        let account = ConnectAccount(name: "me", keyID: "KEY1", issuerID: nil, isActive: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let json = String(decoding: try encoder.encode(account), as: UTF8.self)
        #expect(json == #"{"isActive":true,"keyID":"KEY1","name":"me"}"#)
    }

    @Test func `should show a dash for the issuer ID in the table when the account is an individual key`() {
        let account = ConnectAccount(name: "me", keyID: "KEY1", issuerID: nil, isActive: true)
        #expect(account.tableRow == ["me", "KEY1", "-", "*", "-"])
    }

    @Test func `connect account vendor number is omitted from JSON when nil`() throws {
        let account = ConnectAccount(name: "work", keyID: "KEY1", issuerID: "ISSUER1", isActive: true)
        let data = try JSONEncoder().encode(account)
        let json = String(decoding: data, as: UTF8.self)
        #expect(!json.contains("vendorNumber"))
    }

    @Test func `connect account vendor number is included in JSON when set`() throws {
        let account = ConnectAccount(name: "work", keyID: "KEY1", issuerID: "ISSUER1", isActive: true, vendorNumber: "88012345")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(account)
        let json = String(decoding: data, as: UTF8.self)
        #expect(json.contains("\"vendorNumber\":\"88012345\""))
    }
}
