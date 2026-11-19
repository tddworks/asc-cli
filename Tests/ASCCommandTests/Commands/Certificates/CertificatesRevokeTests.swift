import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct CertificatesRevokeTests {

    @Test func `execute revokes certificate`() async throws {
        let mockRepo = MockCertificates()
        given(mockRepo).revokeCertificate(id: .any).willReturn()

        let cmd = try CertificatesRevoke.parse(["--certificate-id", "cert-42"])
        try await cmd.execute(repo: mockRepo)

        verify(mockRepo).revokeCertificate(id: .value("cert-42")).called(.once)
    }
}
