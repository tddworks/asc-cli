import Foundation
import Mockable
import Testing
@testable import ASCKit

/// Fixtures are captured responses (docs/features/app-privacy/design.md, live on
/// 2026-11-24), ids replaced — never a shape guessed at.
@Suite
struct IrisSDKAppPrivacyRepositoryTests {
    private let session = IrisSession(cookies: "myacinfo=a")
    private static let rowsQuery = [
        URLQueryItem(name: "include", value: "category,grouping,purpose,dataProtection"),
        URLQueryItem(name: "limit", value: "500"),
    ]

    private func ok(_ json: String, status: Int = 200) -> (Data, HTTPURLResponse) {
        (Data(json.utf8), HTTPURLResponse(url: URL(string: "https://appstoreconnect.apple.com")!, statusCode: status, httpVersion: nil, headerFields: nil)!)
    }

    private static let notCollectedRows = #"""
    { "data" : [ { "type" : "appDataUsages", "id" : "usage-1", "relationships" : {
        "category" : { "data" : null }, "grouping" : { "data" : null }, "purpose" : { "data" : null },
        "dataProtection" : { "data" : { "type" : "appDataUsageDataProtections", "id" : "DATA_NOT_COLLECTED" } } },
        "links" : { "self" : "https://appstoreconnect.apple.com/iris/v1/appDataUsages/usage-1" } } ],
      "included" : [ { "type" : "appDataUsageDataProtections", "id" : "DATA_NOT_COLLECTED", "attributes" : { "deleted" : false } } ],
      "meta" : { "paging" : { "total" : 1, "limit" : 500 } } }
    """#

    private static func collectedRow(_ id: String, purpose: String) -> String {
        #"""
        { "type" : "appDataUsages", "id" : "\#(id)", "relationships" : {
            "category" : { "data" : { "type" : "appDataUsageCategories", "id" : "OTHER_USAGE_DATA" } },
            "grouping" : { "data" : { "type" : "appDataUsageGroupings", "id" : "USAGE_DATA" } },
            "purpose" : { "data" : { "type" : "appDataUsagePurposes", "id" : "\#(purpose)" } },
            "dataProtection" : { "data" : { "type" : "appDataUsageDataProtections", "id" : "DATA_NOT_LINKED_TO_YOU" } } } }
        """#
    }

    private static let unanswered = #"""
    { "data" : [ ], "included" : [ ], "meta" : { "paging" : { "total" : 0, "limit" : 500 } } }
    """#

    private static let neverPublished = #"""
    { "data" : { "type" : "appDataUsagesPublishState", "id" : "1234567890",
        "attributes" : { "published" : false, "lastPublished" : null, "lastPublishedBy" : null } } }
    """#

    private static let published = #"""
    { "data" : { "type" : "appDataUsagesPublishState", "id" : "1234567890",
        "attributes" : { "published" : true, "lastPublished" : "2026-11-24T00:14:02-08:00", "lastPublishedBy" : "Dev" } } }
    """#

    private func iris(rows: String, state: String = neverPublished) -> MockIrisAPI {
        let api = MockIrisAPI()
        given(api).get(path: .value("apps/1234567890/dataUsages"), queryItems: .value(Self.rowsQuery), cookies: .value("myacinfo=a"))
            .willReturn(ok(rows))
        given(api).get(path: .value("apps/1234567890/dataUsagePublishState"), queryItems: .value([]), cookies: .value("myacinfo=a"))
            .willReturn(ok(state))
        return api
    }

    // MARK: - reading

    @Test func `should show a new app's label as unanswered and unpublished`() async throws {
        let repo = IrisSDKAppPrivacyRepository(api: iris(rows: Self.unanswered))

        let privacy = try await repo.fetchPrivacy(session: session, appId: "1234567890")

        #expect(privacy == AppPrivacy(appId: "1234567890", dataCollection: .notAnswered, isPublished: false, lastPublishedAt: nil))
    }

    @Test func `should show a published Data Not Collected label with when it went live`() async throws {
        let repo = IrisSDKAppPrivacyRepository(api: iris(rows: Self.notCollectedRows, state: Self.published))

        let privacy = try await repo.fetchPrivacy(session: session, appId: "1234567890")

        #expect(privacy == AppPrivacy(appId: "1234567890", dataCollection: .notCollected, isPublished: true,
                                      lastPublishedAt: "2026-11-24T00:14:02-08:00"))
    }

    @Test func `should list each row with its id under the app it belongs to`() async throws {
        let rows = #"{ "data" : [ \#(Self.collectedRow("usage-1", purpose: "OTHER_PURPOSES")), \#(Self.collectedRow("usage-2", purpose: "ANALYTICS")) ], "included" : [ ] }"#
        let repo = IrisSDKAppPrivacyRepository(api: iris(rows: rows))

        let usages = try await repo.listDataUsages(session: session, appId: "1234567890")

        #expect(usages == [
            DataUsage(id: "usage-1", appId: "1234567890", category: .init(rawValue: "OTHER_USAGE_DATA"),
                      purpose: .init(rawValue: "OTHER_PURPOSES"), protection: .notLinkedToYou),
            DataUsage(id: "usage-2", appId: "1234567890", category: .init(rawValue: "OTHER_USAGE_DATA"),
                      purpose: .init(rawValue: "ANALYTICS"), protection: .notLinkedToYou),
        ])
    }

    // MARK: - changing

    @Test func `should create the not-collected row with the body the page sends`() async throws {
        let api = MockIrisAPI()
        given(api).post(path: .any, body: .any, cookies: .any).willReturn(ok("", status: 201))

        try await IrisSDKAppPrivacyRepository(api: api).createDataUsage(
            session: session, appId: "1234567890", entry: DataUsageEntry(category: nil, purpose: nil, protection: .notCollected)
        )

        verify(api).post(path: .value("appDataUsages"), body: .value(Data(#"{"data":{"relationships":{"app":{"data":{"id":"1234567890","type":"apps"}},"dataProtection":{"data":{"id":"DATA_NOT_COLLECTED","type":"appDataUsageDataProtections"}}},"type":"appDataUsages"}}"#.utf8)), cookies: .value("myacinfo=a")).called(1)
    }

    @Test func `should create a collected row naming its category and purpose`() async throws {
        let api = MockIrisAPI()
        given(api).post(path: .any, body: .any, cookies: .any).willReturn(ok("", status: 201))

        try await IrisSDKAppPrivacyRepository(api: api).createDataUsage(
            session: session, appId: "1234567890",
            entry: DataUsageEntry(category: .init(rawValue: "CRASH_DATA"), purpose: .init(rawValue: "ANALYTICS"), protection: .notLinkedToYou)
        )

        verify(api).post(path: .value("appDataUsages"), body: .value(Data(#"{"data":{"relationships":{"app":{"data":{"id":"1234567890","type":"apps"}},"category":{"data":{"id":"CRASH_DATA","type":"appDataUsageCategories"}},"dataProtection":{"data":{"id":"DATA_NOT_LINKED_TO_YOU","type":"appDataUsageDataProtections"}},"purpose":{"data":{"id":"ANALYTICS","type":"appDataUsagePurposes"}}},"type":"appDataUsages"}}"#.utf8)), cookies: .value("myacinfo=a")).called(1)
    }

    @Test func `should delete a row by its own path`() async throws {
        let api = MockIrisAPI()
        given(api).delete(path: .any, cookies: .any).willReturn(ok("", status: 204))

        try await IrisSDKAppPrivacyRepository(api: api).deleteDataUsage(session: session, dataUsageId: "usage-1")

        verify(api).delete(path: .value("appDataUsages/usage-1"), cookies: .value("myacinfo=a")).called(1)
    }

    @Test func `should publish with the body the page sends`() async throws {
        let api = MockIrisAPI()
        given(api).patch(path: .any, body: .any, cookies: .any).willReturn(ok(Self.published))

        try await IrisSDKAppPrivacyRepository(api: api).publish(session: session, appId: "1234567890")

        verify(api).patch(path: .value("appDataUsagesPublishState/1234567890"), body: .value(Data(#"{"data":{"attributes":{"published":true},"id":"1234567890","type":"appDataUsagesPublishState"}}"#.utf8)), cookies: .value("myacinfo=a")).called(1)
    }
}
