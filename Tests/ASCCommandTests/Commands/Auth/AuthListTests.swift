import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct AuthListTests {

    @Test func `auth list returns all accounts as JSON`() async throws {
        let mockStorage = MockAuthStorage()
        let accounts = [
            ConnectAccount(name: "personal", keyID: "KEY1", issuerID: "ISSUER1", isActive: false),
            ConnectAccount(name: "work", keyID: "KEY2", issuerID: "ISSUER2", isActive: true),
        ]
        given(mockStorage).loadAll().willReturn(accounts)

        var cmd = try AuthList.parse(["--pretty"])
        let output = try await cmd.execute(storage: mockStorage)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "logout" : "asc auth logout --name personal",
                "use" : "asc auth use personal"
              },
              "isActive" : false,
              "issuerID" : "ISSUER1",
              "keyID" : "KEY1",
              "name" : "personal"
            },
            {
              "affordances" : {
                "logout" : "asc auth logout --name work"
              },
              "isActive" : true,
              "issuerID" : "ISSUER2",
              "keyID" : "KEY2",
              "name" : "work"
            }
          ]
        }
        """)
    }

    @Test func `auth list returns empty data when no accounts saved`() async throws {
        let mockStorage = MockAuthStorage()
        given(mockStorage).loadAll().willReturn([])

        var cmd = try AuthList.parse(["--pretty"])
        let output = try await cmd.execute(storage: mockStorage)

        #expect(output == """
        {
          "data" : [

          ]
        }
        """)
    }
}
