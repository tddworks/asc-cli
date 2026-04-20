import Foundation
import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct CertificatesListTests {

    @Test func `listed certificates include type and affordances`() async throws {
        let mockRepo = MockCertificateRepository()
        given(mockRepo).listCertificates(certificateType: .any, limit: .any).willReturn([
            Certificate(id: "cert-1", name: "iOS Distribution", certificateType: .iosDistribution),
        ])

        let cmd = try CertificatesList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "revoke" : "asc certificates revoke --certificate-id cert-1"
              },
              "certificateType" : "IOS_DISTRIBUTION",
              "id" : "cert-1",
              "name" : "iOS Distribution"
            }
          ]
        }
        """)
    }

    @Test func `table output includes all row fields`() async throws {
        let mockRepo = MockCertificateRepository()
        given(mockRepo).listCertificates(certificateType: .any, limit: .any).willReturn([
            Certificate(id: "cert-1", name: "iOS Dist", certificateType: .iosDistribution),
        ])

        let cmd = try CertificatesList.parse(["--output", "table"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("cert-1"))
        #expect(output.contains("IOS_DISTRIBUTION"))
        #expect(output.contains("No"))
    }

    @Test func `expired-only flag filters out unexpired certificates`() async throws {
        let past = Date(timeIntervalSince1970: 1_000_000_000) // year 2001 — expired
        let future = Date(timeIntervalSinceNow: 31_536_000)   // one year from now
        let mockRepo = MockCertificateRepository()
        given(mockRepo).listCertificates(certificateType: .any, limit: .any).willReturn([
            Certificate(id: "cert-expired", name: "Old", certificateType: .iosDistribution, expirationDate: past),
            Certificate(id: "cert-fresh", name: "Fresh", certificateType: .iosDistribution, expirationDate: future),
        ])

        let cmd = try CertificatesList.parse(["--expired-only"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("cert-expired"))
        #expect(!output.contains("cert-fresh"))
    }

    @Test func `before flag filters out certs with expirationDate on or after cutoff`() async throws {
        let cutoff = Date(timeIntervalSince1970: 1_700_000_000)
        let earlier = Date(timeIntervalSince1970: 1_600_000_000)
        let later = Date(timeIntervalSince1970: 1_800_000_000)
        let mockRepo = MockCertificateRepository()
        given(mockRepo).listCertificates(certificateType: .any, limit: .any).willReturn([
            Certificate(id: "cert-early", name: "Early", certificateType: .iosDistribution, expirationDate: earlier),
            Certificate(id: "cert-late", name: "Late", certificateType: .iosDistribution, expirationDate: later),
        ])

        let cmd = try CertificatesList.parse(["--before", "2023-11-14T22:13:20Z"])
        let output = try await cmd.execute(repo: mockRepo)
        _ = cutoff

        #expect(output.contains("cert-early"))
        #expect(!output.contains("cert-late"))
    }

    @Test func `before flag accepts date-only YYYY-MM-DD`() async throws {
        let earlier = Date(timeIntervalSince1970: 1_600_000_000) // 2020-09
        let later = Date(timeIntervalSince1970: 2_000_000_000)   // 2033-05
        let mockRepo = MockCertificateRepository()
        given(mockRepo).listCertificates(certificateType: .any, limit: .any).willReturn([
            Certificate(id: "cert-early", name: "Early", certificateType: .iosDistribution, expirationDate: earlier),
            Certificate(id: "cert-late", name: "Late", certificateType: .iosDistribution, expirationDate: later),
        ])

        let cmd = try CertificatesList.parse(["--before", "2026-11-01"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("cert-early"))
        #expect(!output.contains("cert-late"))
    }

    @Test func `limit flag is forwarded to repository`() async throws {
        let mockRepo = MockCertificateRepository()
        given(mockRepo).listCertificates(certificateType: .any, limit: .value(200)).willReturn([])

        let cmd = try CertificatesList.parse(["--limit", "200", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [

          ]
        }
        """)
    }

    @Test func `optional certificate fields are omitted when nil`() async throws {
        let mockRepo = MockCertificateRepository()
        given(mockRepo).listCertificates(certificateType: .any, limit: .any).willReturn([
            Certificate(
                id: "cert-1",
                name: "Mac Distribution",
                certificateType: .macAppDistribution,
                displayName: "Mac App Distribution",
                serialNumber: "SN-001"
            ),
        ])

        let cmd = try CertificatesList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "revoke" : "asc certificates revoke --certificate-id cert-1"
              },
              "certificateType" : "MAC_APP_DISTRIBUTION",
              "displayName" : "Mac App Distribution",
              "id" : "cert-1",
              "name" : "Mac Distribution",
              "serialNumber" : "SN-001"
            }
          ]
        }
        """)
    }
}
