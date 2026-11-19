import Foundation
import Testing
@testable import ASCKit

final class AppBundleURLProtocolStub: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var reply: (status: Int, body: String) = (200, "{}")
    nonisolated(unsafe) static var lastRequest: URLRequest?
    nonisolated(unsafe) static var lastBody: Data?

    static func makeClient(status: Int, body: String) -> IrisClient {
        reply = (status, body)
        lastRequest = nil
        lastBody = nil
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [AppBundleURLProtocolStub.self]
        return IrisClient(session: URLSession(configuration: config))
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.lastRequest = request
        Self.lastBody = request.httpBody ?? request.httpBodyStream.map { stream in
            stream.open()
            defer { stream.close() }
            var data = Data()
            var buffer = [UInt8](repeating: 0, count: 4096)
            while stream.hasBytesAvailable {
                let read = stream.read(&buffer, maxLength: buffer.count)
                if read <= 0 { break }
                data.append(buffer, count: read)
            }
            return data
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.reply.status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(Self.reply.body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

@Suite(.serialized)
struct IrisSDKAppBundleRepositoryTests {
    private let session = IrisSession(cookies: "myacinfo=a")

    @Test func `should list every app bundle with its versions included`() async throws {
        let client = AppBundleURLProtocolStub.makeClient(status: 200, body: #"""
        {"data":[
          {"id":"b1","type":"apps","attributes":{"name":"Bakery","bundleId":"com.example.bakery","sku":"BAKE","primaryLocale":"en-GB","platformNames":["IOS"]}},
          {"id":"b2","type":"apps","attributes":{}}
        ]}
        """#)

        let bundles = try await IrisSDKAppBundleRepository(client: client).listAppBundles(session: session)

        #expect(bundles == [
            AppBundle(id: "b1", name: "Bakery", bundleId: "com.example.bakery", sku: "BAKE", primaryLocale: "en-GB", platforms: ["IOS"]),
            AppBundle(id: "b2", name: "", bundleId: "", sku: "", primaryLocale: "en-US", platforms: []),
        ])
        #expect(AppBundleURLProtocolStub.lastRequest?.url?.absoluteString
            == "https://appstoreconnect.apple.com/iris/v1/appBundles?include=appBundleVersions&limit=300")
    }

    @Test func `should name a created app as asked when iris leaves the name out`() async throws {
        let client = AppBundleURLProtocolStub.makeClient(status: 201, body: #"""
        {"data":{"id":"new","type":"apps","attributes":{"bundleId":"com.example.new","sku":"NEW","primaryLocale":"en-US","platformNames":["IOS"]}}}
        """#)

        let bundle = try await IrisSDKAppBundleRepository(client: client).createApp(
            session: session, name: "New App", bundleId: "com.example.new", sku: "NEW",
            primaryLocale: "en-US", platforms: ["IOS"], versionString: "1.0"
        )

        #expect(bundle == AppBundle(id: "new", name: "New App", bundleId: "com.example.new", sku: "NEW", primaryLocale: "en-US", platforms: ["IOS"]))
        #expect(AppBundleURLProtocolStub.lastRequest?.httpMethod == "POST")
        #expect(AppBundleURLProtocolStub.lastRequest?.url?.absoluteString == "https://appstoreconnect.apple.com/iris/v1/apps")
    }

    @Test func `should fail with iris's status when it refuses to create the app`() async {
        let client = AppBundleURLProtocolStub.makeClient(status: 409, body: "bundle id taken")

        do {
            _ = try await IrisSDKAppBundleRepository(client: client).createApp(
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
