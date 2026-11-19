import Mockable

@Mockable
public protocol CertificateRepository: Sendable {
    func listCertificates(certificateType: CertificateType?, limit: Int?) async throws -> [Certificate]
    func createCertificate(certificateType: CertificateType, csrContent: String) async throws -> Certificate
    func revokeCertificate(id: String) async throws
}
