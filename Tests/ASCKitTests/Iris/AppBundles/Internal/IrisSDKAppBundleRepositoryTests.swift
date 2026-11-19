import Foundation
import Mockable
import Testing
@testable import ASCKit

@Suite
struct IrisSDKAppBundleRepositoryTests {
    private let session = IrisSession(cookies: "myacinfo=a")

    private func reply(_ status: Int, _ body: String) -> (Data, HTTPURLResponse) {
        let url = URL(string: "https://appstoreconnect.apple.com/iris/v1")!
        return (Data(body.utf8), HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!)
    }

    @Test func `should list every app bundle with its versions included`() async throws {
        let iris = MockIrisAPI()
        given(iris).get(
            path: .value("appBundles"),
            queryItems: .value([URLQueryItem(name: "include", value: "appBundleVersions"), URLQueryItem(name: "limit", value: "300")]),
            cookies: .value("myacinfo=a")
        ).willReturn(reply(200, #"""
        {"data":[
          {"id":"b1","type":"apps","attributes":{"name":"Bakery","bundleId":"com.example.bakery","sku":"BAKE","primaryLocale":"en-GB","platformNames":["IOS"]}},
          {"id":"b2","type":"apps","attributes":{}}
        ]}
        """#))

        let bundles = try await IrisSDKAppBundleRepository(client: iris).listAppBundles(session: session)

        #expect(bundles == [
            AppBundle(id: "b1", name: "Bakery", bundleId: "com.example.bakery", sku: "BAKE", primaryLocale: "en-GB", platforms: ["IOS"]),
            AppBundle(id: "b2", name: "", bundleId: "", sku: "", primaryLocale: "en-US", platforms: []),
        ])
    }

    @Test func `should name a created app as asked when iris leaves the name out`() async throws {
        let iris = MockIrisAPI()
        given(iris).post(path: .value("apps"), body: .any, cookies: .value("myacinfo=a")).willReturn(reply(201, #"""
        {"data":{"id":"new","type":"apps","attributes":{"bundleId":"com.example.new","sku":"NEW","primaryLocale":"en-US","platformNames":["IOS"]}}}
        """#))

        let bundle = try await IrisSDKAppBundleRepository(client: iris).createApp(
            session: session, name: "New App", bundleId: "com.example.new", sku: "NEW",
            primaryLocale: "en-US", platforms: ["IOS"], versionString: "1.0"
        )

        #expect(bundle == AppBundle(id: "new", name: "New App", bundleId: "com.example.new", sku: "NEW", primaryLocale: "en-US", platforms: ["IOS"]))
    }

    @Test func `should fail with iris's status when it refuses to create the app`() async {
        let iris = MockIrisAPI()
        given(iris).post(path: .any, body: .any, cookies: .any)
            .willThrow(IrisAPIError.httpError(statusCode: 409, body: "bundle id taken"))

        do {
            _ = try await IrisSDKAppBundleRepository(client: iris).createApp(
                session: session, name: "Dup", bundleId: "com.example.dup", sku: "DUP",
                primaryLocale: "en-US", platforms: ["IOS"], versionString: "1.0"
            )
            Issue.record("expected iris to refuse")
        } catch IrisAPIError.httpError(let statusCode, let body) {
            #expect(statusCode == 409)
            #expect(body == "bundle id taken")
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }
}
