import Foundation
import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct IrisAppPrivacyTests {
    private func cookies() -> MockIrisCookieProvider {
        let provider = MockIrisCookieProvider()
        given(provider).resolveSession().willReturn(IrisSession(cookies: "myacinfo=a"))
        return provider
    }

    private let unanswered = AppPrivacy(appId: "1234567890", dataCollection: .notAnswered, isPublished: false, lastPublishedAt: nil)
    private let notCollected = AppPrivacy(appId: "1234567890", dataCollection: .notCollected, isPublished: false, lastPublishedAt: nil)
    private let live = AppPrivacy(appId: "1234567890", dataCollection: .notCollected, isPublished: true, lastPublishedAt: "2026-11-24T00:14:02-08:00")

    private func repo(showing privacy: AppPrivacy) -> MockIrisAppPrivacyRepository {
        let repo = MockIrisAppPrivacyRepository()
        given(repo).fetchPrivacy(session: .any, appId: .value("1234567890")).willReturn(privacy)
        given(repo).listDataUsages(session: .any, appId: .value("1234567890")).willReturn([])
        given(repo).createDataUsage(session: .any, appId: .any, entry: .any).willReturn()
        given(repo).deleteDataUsage(session: .any, dataUsageId: .any).willReturn()
        given(repo).publish(session: .any, appId: .any).willReturn()
        return repo
    }

    @Test func `should show an unanswered label as blocking review, with both ways to declare it`() async throws {
        let cmd = try IrisAppPrivacyGet.parse(["--app-id", "1234567890", "--pretty"])

        let output = try await cmd.execute(cookieProvider: cookies(), repo: repo(showing: unanswered))

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "declare" : "asc iris app-privacy declare --app-id 1234567890 --file <privacy.json>",
                "declareNotCollected" : "asc iris app-privacy declare --app-id 1234567890 --not-collected",
                "get" : "asc iris app-privacy get --app-id 1234567890"
              },
              "appId" : "1234567890",
              "blocksSubmission" : true,
              "dataCollection" : "NOT_ANSWERED",
              "isAnswered" : false,
              "isPublished" : false
            }
          ]
        }
        """)
    }

    @Test func `should declare no data collected and offer to publish it`() async throws {
        let cmd = try IrisAppPrivacyDeclare.parse(["--app-id", "1234567890", "--not-collected", "--pretty"])

        let output = try await cmd.execute(cookieProvider: cookies(), repo: repo(showing: notCollected))

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "declare" : "asc iris app-privacy declare --app-id 1234567890 --file <privacy.json>",
                "get" : "asc iris app-privacy get --app-id 1234567890",
                "publish" : "asc iris app-privacy publish --app-id 1234567890"
              },
              "appId" : "1234567890",
              "blocksSubmission" : true,
              "dataCollection" : "NOT_COLLECTED",
              "isAnswered" : true,
              "isPublished" : false
            }
          ]
        }
        """)
    }

    @Test func `should declare the collected data a file lists`() async throws {
        let declared = AppPrivacy(appId: "1234567890", dataCollection: .collected([
            CollectedData(category: .init(rawValue: "CRASH_DATA"), purposes: [.init(rawValue: "ANALYTICS")], isLinkedToYou: false, isUsedToTrackYou: false),
        ]), isPublished: false, lastPublishedAt: nil)
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("privacy-\(UUID().uuidString).json")
        try Data(#"{"collectedData":[{"category":"CRASH_DATA","purposes":["ANALYTICS"],"isLinkedToYou":false,"isUsedToTrackYou":false}]}"#.utf8).write(to: file)
        defer { try? FileManager.default.removeItem(at: file) }
        let cmd = try IrisAppPrivacyDeclare.parse(["--app-id", "1234567890", "--file", file.path, "--pretty"])

        let output = try await cmd.execute(cookieProvider: cookies(), repo: repo(showing: declared))

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "declare" : "asc iris app-privacy declare --app-id 1234567890 --file <privacy.json>",
                "get" : "asc iris app-privacy get --app-id 1234567890",
                "publish" : "asc iris app-privacy publish --app-id 1234567890"
              },
              "appId" : "1234567890",
              "blocksSubmission" : true,
              "collectedData" : [
                {
                  "category" : "CRASH_DATA",
                  "isLinkedToYou" : false,
                  "isUsedToTrackYou" : false,
                  "purposes" : [
                    "ANALYTICS"
                  ]
                }
              ],
              "dataCollection" : "COLLECTED",
              "isAnswered" : true,
              "isPublished" : false
            }
          ]
        }
        """)
    }

    @Test func `should refuse to be told both that nothing is collected and what is`() {
        #expect(throws: (any Error).self) {
            try IrisAppPrivacyDeclare.parse(["--app-id", "1234567890", "--not-collected", "--file", "privacy.json"])
        }
    }

    @Test func `should refuse a declare that says neither`() {
        #expect(throws: (any Error).self) {
            try IrisAppPrivacyDeclare.parse(["--app-id", "1234567890"])
        }
    }

    @Test func `should publish the label and show it no longer blocks review`() async throws {
        let repo = MockIrisAppPrivacyRepository()
        given(repo).fetchPrivacy(session: .any, appId: .value("1234567890")).willReturn(notCollected)
        given(repo).fetchPrivacy(session: .any, appId: .value("1234567890")).willReturn(live)
        given(repo).publish(session: .any, appId: .value("1234567890")).willReturn()
        let cmd = try IrisAppPrivacyPublish.parse(["--app-id", "1234567890", "--pretty"])

        let output = try await cmd.execute(cookieProvider: cookies(), repo: repo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "declare" : "asc iris app-privacy declare --app-id 1234567890 --file <privacy.json>",
                "get" : "asc iris app-privacy get --app-id 1234567890"
              },
              "appId" : "1234567890",
              "blocksSubmission" : false,
              "dataCollection" : "NOT_COLLECTED",
              "isAnswered" : true,
              "isPublished" : true,
              "lastPublishedAt" : "2026-11-24T00:14:02-08:00"
            }
          ]
        }
        """)
    }
}
