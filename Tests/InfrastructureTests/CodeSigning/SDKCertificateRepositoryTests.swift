@preconcurrency import AppStoreConnect_Swift_SDK
import Foundation
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKCertificateRepositoryTests {

    @Test func `listCertificates maps name and type`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(CertificatesResponse(
            data: [
                AppStoreConnect_Swift_SDK.Certificate(
                    type: .certificates,
                    id: "cert-1",
                    attributes: .init(
                        name: "iOS Distribution",
                        certificateType: .iosDistribution,
                        displayName: "iPhone Distribution",
                        serialNumber: "ABC123"
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKCertificateRepository(client: stub)
        let result = try await repo.listCertificates(certificateType: nil, limit: nil)

        #expect(result[0].id == "cert-1")
        #expect(result[0].name == "iOS Distribution")
        #expect(result[0].certificateType == .iosDistribution)
        #expect(result[0].displayName == "iPhone Distribution")
        #expect(result[0].serialNumber == "ABC123")
    }

    @Test func `listCertificates maps expiration date`() async throws {
        let expiration = Date(timeIntervalSince1970: 2_000_000_000)
        let stub = StubAPIClient()
        stub.willReturn(CertificatesResponse(
            data: [
                AppStoreConnect_Swift_SDK.Certificate(
                    type: .certificates,
                    id: "cert-1",
                    attributes: .init(certificateType: .distribution, expirationDate: expiration)
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKCertificateRepository(client: stub)
        let result = try await repo.listCertificates(certificateType: nil, limit: nil)

        #expect(result[0].expirationDate == expiration)
    }

    @Test func `revokeCertificate calls void endpoint`() async throws {
        let stub = StubAPIClient()
        let repo = SDKCertificateRepository(client: stub)

        try await repo.revokeCertificate(id: "cert-1")

        #expect(stub.voidRequestCalled == true)
    }
}
