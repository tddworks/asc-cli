import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct IrisStatusTests {

    @Test func `status shows source and cookie count with affordances`() async throws {
        let mockCookieProvider = MockIrisCookieProvider()
        given(mockCookieProvider).resolveStatus().willReturn(
            Domain.IrisStatus(source: .browser, cookieCount: 5)
        )

        let cmd = try ASCCommand.IrisStatus.parse(["--pretty"])
        let output = try await cmd.execute(cookieProvider: mockCookieProvider)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "createApp" : "asc iris apps create --name <name> --bundle-id <id> --sku <sku>",
                "listApps" : "asc iris apps list",
                "submitIAP" : "asc iris iap-submissions create --iap-id <iap-id>"
              },
              "cookieCount" : 5,
              "source" : "browser"
            }
          ]
        }
        """)
    }

    @Test func `status shows environment source`() async throws {
        let mockCookieProvider = MockIrisCookieProvider()
        given(mockCookieProvider).resolveStatus().willReturn(
            Domain.IrisStatus(source: .environment, cookieCount: 3)
        )

        let cmd = try ASCCommand.IrisStatus.parse(["--pretty"])
        let output = try await cmd.execute(cookieProvider: mockCookieProvider)

        #expect(output.contains("\"source\" : \"environment\""))
    }
}
