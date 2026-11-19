import Foundation
import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct CertificatesCreateTests {

    private static let fakePEM = """
    -----BEGIN CERTIFICATE REQUEST-----
    MIIBxxx
    -----END CERTIFICATE REQUEST-----
    """

    private func makeMock(id: String = "cert-1") -> MockCertificates {
        let mock = MockCertificates()
        given(mock).createCertificate(certificateType: .any, csrContent: .any).willReturn(
            Certificate(id: id, name: "Mac App Distribution", certificateType: .macAppDistribution)
        )
        return mock
    }

    // MARK: - --csr-content
    // NOTE: --csr-content cannot accept raw PEM files because PEM starts with
    // "-----BEGIN" which ArgumentParser treats as an invalid option flag (starts with "--").
    // Use --csr-path for PEM files. --csr-content works for pre-processed/encoded strings.

    @Test func `create with csr-content passes non-pem string to repository`() async throws {
        let cmd = try CertificatesCreate.parse([
            "--type", "MAC_APP_DISTRIBUTION",
            "--csr-content", "base64encodedCSRcontent==",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: makeMock(id: "cert-1"))

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "revoke" : "asc certificates revoke --certificate-id cert-1"
              },
              "certificateType" : "MAC_APP_DISTRIBUTION",
              "id" : "cert-1",
              "name" : "Mac App Distribution"
            }
          ]
        }
        """)
    }

    // MARK: - --csr-path

    @Test func `create with csr-path reads file and passes pem to repository`() async throws {
        let tmpFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-\(UUID().uuidString).csr")
        try Self.fakePEM.write(to: tmpFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tmpFile) }

        let cmd = try CertificatesCreate.parse([
            "--type", "MAC_APP_DISTRIBUTION",
            "--csr-path", tmpFile.path,
            "--pretty",
        ])
        let output = try await cmd.execute(repo: makeMock(id: "cert-2"))

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "revoke" : "asc certificates revoke --certificate-id cert-2"
              },
              "certificateType" : "MAC_APP_DISTRIBUTION",
              "id" : "cert-2",
              "name" : "Mac App Distribution"
            }
          ]
        }
        """)
    }

    // MARK: - Validation errors

    @Test func `create with neither flag throws validation error`() async throws {
        let cmd = try CertificatesCreate.parse(["--type", "IOS_DISTRIBUTION"])
        await #expect(throws: (any Error).self) {
            _ = try await cmd.execute(repo: MockCertificates())
        }
    }

    @Test func `create with invalid type throws validation error`() async throws {
        let tmpFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-\(UUID().uuidString).csr")
        try Self.fakePEM.write(to: tmpFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tmpFile) }

        let cmd = try CertificatesCreate.parse([
            "--type", "BOGUS_TYPE",
            "--csr-path", tmpFile.path,
        ])
        await #expect(throws: (any Error).self) {
            _ = try await cmd.execute(repo: MockCertificates())
        }
    }
}
