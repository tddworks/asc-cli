import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct BetaGroupsListTests {

    @Test func `groups list includes affordances and appId in json output`() async throws {
        let mockRepo = MockTestFlightRepository()
        given(mockRepo).listBetaGroups(appId: .any, limit: .any).willReturn(
            PaginatedResponse(data: [
                BetaGroup(id: "g-1", appId: "app-1", name: "External Testers", isInternalGroup: false),
                BetaGroup(id: "g-2", appId: "app-2", name: "Internal Team", isInternalGroup: true),
            ], nextCursor: nil)
        )

        let cmd = try BetaGroupsList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "exportTesters" : "asc testflight testers export --group-id g-1",
                "importTesters" : "asc testflight testers import --group-id g-1 --file testers.csv",
                "listTesters" : "asc testflight testers list --group-id g-1"
              },
              "appId" : "app-1",
              "id" : "g-1",
              "isInternalGroup" : false,
              "name" : "External Testers",
              "publicLinkEnabled" : false
            },
            {
              "affordances" : {
                "exportTesters" : "asc testflight testers export --group-id g-2",
                "importTesters" : "asc testflight testers import --group-id g-2 --file testers.csv",
                "listTesters" : "asc testflight testers list --group-id g-2"
              },
              "appId" : "app-2",
              "id" : "g-2",
              "isInternalGroup" : true,
              "name" : "Internal Team",
              "publicLinkEnabled" : false
            }
          ]
        }
        """)
    }
}

@Suite
struct BetaTestersListTests {

    @Test func `testers list includes affordances and groupId in json output`() async throws {
        let mockRepo = MockTestFlightRepository()
        given(mockRepo).listBetaTesters(groupId: .any, limit: .any).willReturn(
            PaginatedResponse(data: [
                BetaTester(id: "t-1", groupId: "g-1", firstName: "Jane", lastName: "Doe", email: "jane@example.com", inviteType: .email),
            ], nextCursor: nil)
        )

        let cmd = try BetaTestersList.parse(["--group-id", "g-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listSiblings" : "asc testflight testers list --group-id g-1",
                "remove" : "asc testflight testers remove --group-id g-1 --tester-id t-1"
              },
              "email" : "jane@example.com",
              "firstName" : "Jane",
              "groupId" : "g-1",
              "id" : "t-1",
              "inviteType" : "EMAIL",
              "lastName" : "Doe"
            }
          ]
        }
        """)
    }

    @Test func `testers list omits nil optional fields from json output`() async throws {
        let mockRepo = MockTestFlightRepository()
        given(mockRepo).listBetaTesters(groupId: .any, limit: .any).willReturn(
            PaginatedResponse(data: [
                BetaTester(id: "t-1", groupId: "g-1", firstName: "Unknown", lastName: nil, email: nil, inviteType: nil),
            ], nextCursor: nil)
        )

        let cmd = try BetaTestersList.parse(["--group-id", "g-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listSiblings" : "asc testflight testers list --group-id g-1",
                "remove" : "asc testflight testers remove --group-id g-1 --tester-id t-1"
              },
              "firstName" : "Unknown",
              "groupId" : "g-1",
              "id" : "t-1"
            }
          ]
        }
        """)
    }
}

@Suite
struct BetaTestersAddTests {

    @Test func `testers add returns created tester with affordances`() async throws {
        let mockRepo = MockTestFlightRepository()
        given(mockRepo).addBetaTester(groupId: .any, email: .any, firstName: .any, lastName: .any).willReturn(
            BetaTester(id: "t-new", groupId: "g-1", firstName: "New", lastName: nil, email: "new@example.com", inviteType: .email)
        )

        let cmd = try BetaTestersAdd.parse(["--group-id", "g-1", "--email", "new@example.com", "--first-name", "New", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listSiblings" : "asc testflight testers list --group-id g-1",
                "remove" : "asc testflight testers remove --group-id g-1 --tester-id t-new"
              },
              "email" : "new@example.com",
              "firstName" : "New",
              "groupId" : "g-1",
              "id" : "t-new",
              "inviteType" : "EMAIL"
            }
          ]
        }
        """)
    }
}

@Suite
struct BetaTestersRemoveTests {

    @Test func `testers remove returns confirmation message`() async throws {
        let mockRepo = MockTestFlightRepository()
        given(mockRepo).removeBetaTester(groupId: .any, testerId: .any).willReturn()

        let cmd = try BetaTestersRemove.parse(["--group-id", "g-1", "--tester-id", "t-1"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == "Removed tester t-1 from group g-1")
    }
}

@Suite
struct BetaTestersImportTests {

    @Test func `testers import parses csv and adds each tester`() async throws {
        let mockRepo = MockTestFlightRepository()
        given(mockRepo).addBetaTester(groupId: .any, email: .any, firstName: .any, lastName: .any)
            .willReturn(BetaTester(id: "t-1", groupId: "g-1", firstName: "Jane", lastName: "Doe", email: "jane@example.com"))
            .willReturn(BetaTester(id: "t-2", groupId: "g-1", firstName: "John", lastName: nil, email: "john@example.com"))

        let csvContent = """
        email,firstName,lastName
        jane@example.com,Jane,Doe
        john@example.com,John,
        """

        let cmd = try BetaTestersImport.parse(["--group-id", "g-1", "--file", "ignored.csv", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo, csvContent: csvContent)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listSiblings" : "asc testflight testers list --group-id g-1",
                "remove" : "asc testflight testers remove --group-id g-1 --tester-id t-1"
              },
              "email" : "jane@example.com",
              "firstName" : "Jane",
              "groupId" : "g-1",
              "id" : "t-1",
              "lastName" : "Doe"
            },
            {
              "affordances" : {
                "listSiblings" : "asc testflight testers list --group-id g-1",
                "remove" : "asc testflight testers remove --group-id g-1 --tester-id t-2"
              },
              "email" : "john@example.com",
              "firstName" : "John",
              "groupId" : "g-1",
              "id" : "t-2"
            }
          ]
        }
        """)
    }

    @Test func `testers import skips header row and empty lines`() async throws {
        let mockRepo = MockTestFlightRepository()
        given(mockRepo).addBetaTester(groupId: .any, email: .any, firstName: .any, lastName: .any)
            .willReturn(BetaTester(id: "t-1", groupId: "g-1", email: "single@example.com"))

        let csvContent = """
        email,firstName,lastName
        single@example.com,,

        """

        let cmd = try BetaTestersImport.parse(["--group-id", "g-1", "--file", "ignored.csv", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo, csvContent: csvContent)

        #expect(output.contains("\"single@example.com\""))
    }
}

@Suite
struct BetaTestersExportTests {

    @Test func `testers export formats testers as csv`() async throws {
        let mockRepo = MockTestFlightRepository()
        given(mockRepo).listBetaTesters(groupId: .any, limit: .any).willReturn(
            PaginatedResponse(data: [
                BetaTester(id: "t-1", groupId: "g-1", firstName: "Jane", lastName: "Doe", email: "jane@example.com"),
                BetaTester(id: "t-2", groupId: "g-1", firstName: "John", lastName: "Smith", email: "john@example.com"),
            ], nextCursor: nil)
        )

        let cmd = try BetaTestersExport.parse(["--group-id", "g-1"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        email,firstName,lastName
        jane@example.com,Jane,Doe
        john@example.com,John,Smith
        """)
    }

    @Test func `testers export handles nil name fields as empty strings in csv`() async throws {
        let mockRepo = MockTestFlightRepository()
        given(mockRepo).listBetaTesters(groupId: .any, limit: .any).willReturn(
            PaginatedResponse(data: [
                BetaTester(id: "t-1", groupId: "g-1", firstName: nil, lastName: nil, email: "anon@example.com"),
            ], nextCursor: nil)
        )

        let cmd = try BetaTestersExport.parse(["--group-id", "g-1"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        email,firstName,lastName
        anon@example.com,,
        """)
    }
}
