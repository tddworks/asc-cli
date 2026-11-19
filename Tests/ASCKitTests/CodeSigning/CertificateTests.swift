import Foundation
import Testing
@testable import ASCKit

@Suite
struct CertificateTests {

    @Test func `certificate carries all fields`() {
        let cert = MockRepositoryFactory.makeCertificate(
            id: "cert-1",
            name: "iOS Distribution",
            certificateType: .iosDistribution,
            displayName: "iPhone Distribution",
            serialNumber: "ABC123"
        )
        #expect(cert.id == "cert-1")
        #expect(cert.name == "iOS Distribution")
        #expect(cert.certificateType == .iosDistribution)
        #expect(cert.displayName == "iPhone Distribution")
        #expect(cert.serialNumber == "ABC123")
    }

    @Test func `certificate is not expired when expiration date is in the future`() {
        let future = Date().addingTimeInterval(3600)
        let cert = MockRepositoryFactory.makeCertificate(expirationDate: future)
        #expect(cert.isExpired == false)
    }

    @Test func `certificate is expired when expiration date is in the past`() {
        let past = Date().addingTimeInterval(-3600)
        let cert = MockRepositoryFactory.makeCertificate(expirationDate: past)
        #expect(cert.isExpired == true)
    }

    @Test func `certificate without expiration date is not expired`() {
        let cert = MockRepositoryFactory.makeCertificate(expirationDate: nil)
        #expect(cert.isExpired == false)
    }

    @Test func `certificate type raw values match asc api`() {
        #expect(CertificateType.iosDevelopment.rawValue == "IOS_DEVELOPMENT")
        #expect(CertificateType.iosDistribution.rawValue == "IOS_DISTRIBUTION")
        #expect(CertificateType.macAppDevelopment.rawValue == "MAC_APP_DEVELOPMENT")
        #expect(CertificateType.distribution.rawValue == "DISTRIBUTION")
    }
}
