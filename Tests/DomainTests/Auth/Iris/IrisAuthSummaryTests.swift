import Foundation
import Testing
@testable import Domain

@Suite
struct IrisAuthSummaryTests {

    @Test func `summary uses email as id for table view`() {
        let summary = IrisAuthSummary(
            userEmail: "user@example.com",
            providerID: 12345,
            teamId: "TEAM-1",
            expiresAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        #expect(summary.id == "user@example.com")
        #expect(summary.userEmail == "user@example.com")
        #expect(summary.providerID == 12345)
        #expect(summary.teamId == "TEAM-1")
    }

    @Test func `summary built from session preserves user-facing fields and drops secrets`() {
        let session = IrisAuthSession(
            cookies: "myacinfo=SECRET; itctx=ALSO_SECRET",
            scnt: "secret-scnt",
            serviceKey: "secret-key",
            appleIDSessionID: "secret-session",
            providerID: 9999,
            teamId: "T-9",
            userEmail: "alice@example.com",
            expiresAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let summary = IrisAuthSummary(session)
        #expect(summary.userEmail == "alice@example.com")
        #expect(summary.providerID == 9999)
        #expect(summary.teamId == "T-9")
        // The summary intentionally has no surface for secrets — verified by absence of
        // those fields on the type. The encoded JSON must therefore omit them too.
        let encoded = try! JSONEncoder().encode(summary)
        let raw = String(decoding: encoded, as: UTF8.self)
        #expect(!raw.contains("SECRET"))
        #expect(!raw.contains("scnt"))
        #expect(!raw.contains("serviceKey"))
    }

    @Test func `summary affordances point to logout and status`() {
        let summary = IrisAuthSummary(
            userEmail: "u@x.com", providerID: nil, teamId: nil,
            expiresAt: Date()
        )
        #expect(summary.affordances["logout"] == "asc iris auth logout")
        #expect(summary.affordances["status"] == "asc iris status")
    }

    @Test func `summary table row formats expiresAt as ISO8601`() {
        let summary = IrisAuthSummary(
            userEmail: "u@x.com", providerID: 42, teamId: "T-1",
            expiresAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let row = summary.tableRow
        #expect(row[0] == "u@x.com")
        #expect(row[1] == "42")
        #expect(row[2] == "T-1")
        #expect(row[3] == "2023-11-14T22:13:20Z")
    }

    @Test func `summary table row leaves provider and team empty when unknown`() {
        let summary = IrisAuthSummary(
            userEmail: "u@x.com", providerID: nil, teamId: nil,
            expiresAt: Date(timeIntervalSince1970: 0)
        )
        let row = summary.tableRow
        #expect(row[1] == "")
        #expect(row[2] == "")
    }

    @Test func `summary table headers list email, provider, team, and expiry`() {
        #expect(IrisAuthSummary.tableHeaders == ["Email", "Provider", "Team", "Expires"])
    }
}
