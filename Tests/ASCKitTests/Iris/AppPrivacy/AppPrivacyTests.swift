import Foundation
import Mockable
import Testing
@testable import ASCKit

@Suite
struct AppPrivacyTests {
    private let session = IrisSession(cookies: "myacinfo=a")

    private func usage(_ id: String, _ category: String?, _ purpose: String?, _ protection: DataProtection) -> DataUsage {
        DataUsage(id: id, appId: "1234567890", category: category.map(DataCategory.init(rawValue:)),
                  purpose: purpose.map(DataPurpose.init(rawValue:)), protection: protection)
    }

    private func label(_ usages: [DataUsage], published: Bool = false) -> AppPrivacy {
        AppPrivacy(appId: "1234567890", dataUsages: usages, isPublished: published,
                   lastPublishedAt: published ? "2026-11-24T00:14:02-08:00" : nil)
    }

    private func json(_ privacy: AppPrivacy) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return String(decoding: try encoder.encode(privacy), as: UTF8.self)
    }

    // MARK: - what the label says (laws 1, 7)

    @Test func `should be unanswered and block review when nothing is declared`() throws {
        #expect(try json(label([])) == #"{"appId":"1234567890","blocksSubmission":true,"dataCollection":"NOT_ANSWERED","isAnswered":false,"isPublished":false}"#)
    }

    @Test func `should say no data is collected when its one row says so`() {
        #expect(label([usage("u-1", nil, nil, .notCollected)]).dataCollection == .notCollected)
    }

    @Test func `should show each collected data type once with every purpose it is used for`() {
        let privacy = label([
            usage("u-1", "OTHER_USAGE_DATA", "OTHER_PURPOSES", .notLinkedToYou),
            usage("u-2", "OTHER_USAGE_DATA", "ANALYTICS", .notLinkedToYou),
            usage("u-3", "EMAIL_ADDRESS", "APP_FUNCTIONALITY", .linkedToYou),
            usage("u-4", "EMAIL_ADDRESS", nil, .usedToTrackYou),
        ])

        #expect(privacy.dataCollection == .collected([
            CollectedData(category: .init(rawValue: "EMAIL_ADDRESS"), purposes: [.init(rawValue: "APP_FUNCTIONALITY")],
                          isLinkedToYou: true, isUsedToTrackYou: true),
            CollectedData(category: .init(rawValue: "OTHER_USAGE_DATA"), purposes: [.init(rawValue: "ANALYTICS"), .init(rawValue: "OTHER_PURPOSES")],
                          isLinkedToYou: false, isUsedToTrackYou: false),
        ]))
    }

    @Test func `should stop blocking review once an answer is published`() throws {
        #expect(try json(label([usage("u-1", "CRASH_DATA", "ANALYTICS", .notLinkedToYou)], published: true))
            == #"{"appId":"1234567890","blocksSubmission":false,"collectedData":[{"category":"CRASH_DATA","isLinkedToYou":false,"isUsedToTrackYou":false,"purposes":["ANALYTICS"]}],"dataCollection":"COLLECTED","isAnswered":true,"isPublished":true,"lastPublishedAt":"2026-11-24T00:14:02-08:00"}"#)
    }

    @Test func `should still block review when the answer is declared but not published`() {
        #expect(label([usage("u-1", nil, nil, .notCollected)]).blocksSubmission)
    }

    @Test func `should read back the label it wrote`() throws {
        let privacy = label([usage("u-1", "CRASH_DATA", "ANALYTICS", .notLinkedToYou)], published: true)
        #expect(try JSONDecoder().decode(AppPrivacy.self, from: Data(try json(privacy).utf8)) == privacy)
    }

    // MARK: - affordances (law 4)

    @Test func `should offer to declare an unanswered label either way, and not to publish it`() {
        let privacy = label([])
        #expect(privacy.affordances == [
            "get": "asc iris app-privacy get --app-id 1234567890",
            "declare": "asc iris app-privacy declare --app-id 1234567890 --file <privacy.json>",
            "declareNotCollected": "asc iris app-privacy declare --app-id 1234567890 --not-collected",
        ])
    }

    @Test func `should offer to publish a declared label that isn't live`() {
        let privacy = label([usage("u-1", nil, nil, .notCollected)])
        #expect(privacy.affordances == [
            "get": "asc iris app-privacy get --app-id 1234567890",
            "declare": "asc iris app-privacy declare --app-id 1234567890 --file <privacy.json>",
            "publish": "asc iris app-privacy publish --app-id 1234567890",
        ])
    }

    @Test func `should not offer to publish a label that is already live`() {
        #expect(label([usage("u-1", nil, nil, .notCollected)], published: true).affordances["publish"] == nil)
    }

    @Test func `should link the label over REST under its app`() {
        let privacy = label([usage("u-1", nil, nil, .notCollected)])
        #expect(privacy.apiLinks["get"] == APILink(href: "/api/v1/iris/apps/1234567890/app-privacy", method: "GET"))
        #expect(privacy.apiLinks["declare"] == APILink(href: "/api/v1/iris/apps/1234567890/app-privacy/declare", method: "POST"))
        #expect(privacy.apiLinks["publish"] == APILink(href: "/api/v1/iris/apps/1234567890/app-privacy/publish", method: "POST"))
    }

    // MARK: - publish (law 5)

    @Test func `should refuse to publish a label nothing is declared on`() async {
        await #expect(throws: AppPrivacyError.nothingDeclared(appId: "1234567890")) {
            try await label([]).publish(session: session, repo: MockIrisAppPrivacyRepository())
        }
    }

    @Test func `should show the label live after publishing it`() async throws {
        let live = label([usage("u-1", nil, nil, .notCollected)], published: true)
        let repo = MockIrisAppPrivacyRepository()
        given(repo).publish(session: .any, appId: .value("1234567890")).willReturn()
        given(repo).fetchPrivacy(session: .any, appId: .value("1234567890")).willReturn(live)

        let published = try await label([usage("u-1", nil, nil, .notCollected)]).publish(session: session, repo: repo)

        #expect(published.isPublished)
    }

    // MARK: - declare (laws 3, 6)

    @Test func `should show the label as Apple now holds it after declaring`() async throws {
        let declared = label([usage("u-2", nil, nil, .notCollected)])
        let repo = MockIrisAppPrivacyRepository()
        given(repo).listDataUsages(session: .any, appId: .value("1234567890")).willReturn([usage("u-1", "CRASH_DATA", "ANALYTICS", .notLinkedToYou)])
        given(repo).deleteDataUsage(session: .any, dataUsageId: .any).willReturn()
        given(repo).createDataUsage(session: .any, appId: .any, entry: .any).willReturn()
        given(repo).fetchPrivacy(session: .any, appId: .value("1234567890")).willReturn(declared)

        let privacy = try await label([]).declare(.notCollected, session: session, repo: repo)

        #expect(privacy.dataCollection == .notCollected)
        #expect(!privacy.isPublished)
    }

    @Test func `should refuse a declaration with a data type it doesn't know before anything reaches Apple`() async {
        let declaration = PrivacyDeclaration.collected([
            CollectedData(category: .init(rawValue: "EMAIL"), purposes: [.init(rawValue: "ANALYTICS")], isLinkedToYou: true, isUsedToTrackYou: false),
        ])
        await #expect(throws: AppPrivacyError.unknownCategory("EMAIL")) {
            try await label([]).declare(declaration, session: session, repo: MockIrisAppPrivacyRepository())
        }
    }
}
