@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKCertificateRepository: CertificateRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listCertificates(certificateType: Domain.CertificateType?, limit: Int?) async throws -> [Domain.Certificate] {
        let filterType = certificateType.flatMap {
            APIEndpoint.V1.Certificates.GetParameters.FilterCertificateType(rawValue: $0.rawValue)
        }
        let request = APIEndpoint.v1.certificates.get(parameters: .init(
            filterCertificateType: filterType.map { [$0] },
            limit: limit
        ))
        let response = try await client.request(request)
        return response.data.map(mapCertificate)
    }

    public func createCertificate(certificateType: Domain.CertificateType, csrContent: String) async throws -> Domain.Certificate {
        guard let sdkType = AppStoreConnect_Swift_SDK.CertificateType(rawValue: certificateType.rawValue) else {
            throw APIError.unknown("Unsupported certificate type: \(certificateType.rawValue)")
        }
        let body = CertificateCreateRequest(data: .init(
            type: .certificates,
            attributes: .init(csrContent: csrContent, certificateType: sdkType)
        ))
        let response = try await client.request(APIEndpoint.v1.certificates.post(body))
        return mapCertificate(response.data)
    }

    public func revokeCertificate(id: String) async throws {
        try await client.request(APIEndpoint.v1.certificates.id(id).delete)
    }

    // MARK: - Mapper

    private func mapCertificate(_ sdkCert: AppStoreConnect_Swift_SDK.Certificate) -> Domain.Certificate {
        let certType = sdkCert.attributes?.certificateType.flatMap {
            Domain.CertificateType(rawValue: $0.rawValue)
        } ?? .distribution
        let platform = sdkCert.attributes?.platform.flatMap {
            Domain.BundleIDPlatform(rawValue: $0.rawValue)
        }
        return Domain.Certificate(
            id: sdkCert.id,
            name: sdkCert.attributes?.name ?? "",
            certificateType: certType,
            displayName: sdkCert.attributes?.displayName,
            serialNumber: sdkCert.attributes?.serialNumber,
            platform: platform,
            expirationDate: sdkCert.attributes?.expirationDate,
            certificateContent: sdkCert.attributes?.certificateContent
        )
    }
}
