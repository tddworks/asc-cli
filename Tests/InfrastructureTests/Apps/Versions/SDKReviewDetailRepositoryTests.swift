@preconcurrency import AppStoreConnect_Swift_SDK
import Foundation
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKReviewDetailRepositoryTests {

    @Test func `getReviewDetail injects versionId and maps contact fields`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppStoreReviewDetailResponse(
            data: AppStoreConnect_Swift_SDK.AppStoreReviewDetail(
                type: .appStoreReviewDetails,
                id: "rd-1",
                attributes: .init(
                    contactFirstName: "Jane",
                    contactLastName: "Smith",
                    contactPhone: "+1-555-0100",
                    contactEmail: "jane@example.com",
                    demoAccountName: nil,
                    demoAccountPassword: nil,
                    isDemoAccountRequired: false,
                    notes: nil
                )
            ),
            links: .init(this: "")
        ))

        let repo = SDKReviewDetailRepository(client: stub)
        let result = try await repo.getReviewDetail(versionId: "v-42")

        #expect(result.id == "rd-1")
        #expect(result.versionId == "v-42")
        #expect(result.contactFirstName == "Jane")
        #expect(result.contactLastName == "Smith")
        #expect(result.contactPhone == "+1-555-0100")
        #expect(result.contactEmail == "jane@example.com")
        #expect(result.demoAccountRequired == false)
    }

    @Test func `getReviewDetail maps demoAccount fields`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppStoreReviewDetailResponse(
            data: AppStoreConnect_Swift_SDK.AppStoreReviewDetail(
                type: .appStoreReviewDetails,
                id: "rd-2",
                attributes: .init(
                    contactFirstName: nil,
                    contactLastName: nil,
                    contactPhone: nil,
                    contactEmail: nil,
                    demoAccountName: "demo_user",
                    demoAccountPassword: "secret123",
                    isDemoAccountRequired: true,
                    notes: nil
                )
            ),
            links: .init(this: "")
        ))

        let repo = SDKReviewDetailRepository(client: stub)
        let result = try await repo.getReviewDetail(versionId: "v-99")

        #expect(result.demoAccountRequired == true)
        #expect(result.demoAccountName == "demo_user")
        #expect(result.demoAccountPassword == "secret123")
        #expect(result.hasContact == false)
    }

    @Test func `getReviewDetail returns empty detail when API throws`() async throws {
        let repo = SDKReviewDetailRepository(client: ReviewDetailThrowingStub())
        let result = try await repo.getReviewDetail(versionId: "v-empty")

        #expect(result.id == "")
        #expect(result.versionId == "v-empty")
        #expect(result.contactFirstName == nil)
        #expect(result.hasContact == false)
        #expect(result.demoAccountRequired == false)
    }

    @Test func `upsertReviewDetail creates new record when none exists`() async throws {
        let sequenced = SequencedStubAPIClient()
        // First call: GET returns empty (throws)
        // We simulate "not found" by making a stub that throws for the first request
        // then returns a valid response for POST
        let stub = SequencedGetThrowStub()
        stub.postResponse = AppStoreReviewDetailResponse(
            data: AppStoreConnect_Swift_SDK.AppStoreReviewDetail(
                type: .appStoreReviewDetails,
                id: "rd-new",
                attributes: .init(
                    contactFirstName: "Jane",
                    contactLastName: "Smith",
                    contactPhone: "+1-555-0101",
                    contactEmail: "jane@example.com",
                    demoAccountName: nil,
                    demoAccountPassword: nil,
                    isDemoAccountRequired: false,
                    notes: nil
                )
            ),
            links: .init(this: "")
        )
        let repo = SDKReviewDetailRepository(client: stub)
        let update = Domain.ReviewDetailUpdate(
            contactFirstName: "Jane",
            contactLastName: "Smith",
            contactPhone: "+1-555-0101",
            contactEmail: "jane@example.com"
        )
        let result = try await repo.upsertReviewDetail(versionId: "v-1", update: update)

        #expect(result.id == "rd-new")
        #expect(result.versionId == "v-1")
        #expect(result.contactFirstName == "Jane")
        #expect(result.contactEmail == "jane@example.com")
    }

    @Test func `upsertReviewDetail patches existing record`() async throws {
        let stub = SequencedStubAPIClient()
        // First call: GET returns existing review detail
        stub.enqueue(AppStoreReviewDetailResponse(
            data: AppStoreConnect_Swift_SDK.AppStoreReviewDetail(
                type: .appStoreReviewDetails,
                id: "rd-existing",
                attributes: .init(
                    contactFirstName: "Old",
                    contactLastName: "Name",
                    contactPhone: "+1-555-0000",
                    contactEmail: "old@example.com",
                    demoAccountName: nil,
                    demoAccountPassword: nil,
                    isDemoAccountRequired: false,
                    notes: nil
                )
            ),
            links: .init(this: "")
        ))
        // Second call: PATCH returns updated detail
        stub.enqueue(AppStoreReviewDetailResponse(
            data: AppStoreConnect_Swift_SDK.AppStoreReviewDetail(
                type: .appStoreReviewDetails,
                id: "rd-existing",
                attributes: .init(
                    contactFirstName: "New",
                    contactLastName: "Name",
                    contactPhone: "+1-555-9999",
                    contactEmail: "new@example.com",
                    demoAccountName: nil,
                    demoAccountPassword: nil,
                    isDemoAccountRequired: false,
                    notes: "Use staging"
                )
            ),
            links: .init(this: "")
        ))
        let repo = SDKReviewDetailRepository(client: stub)
        let update = Domain.ReviewDetailUpdate(
            contactFirstName: "New",
            contactPhone: "+1-555-9999",
            contactEmail: "new@example.com",
            notes: "Use staging"
        )
        let result = try await repo.upsertReviewDetail(versionId: "v-2", update: update)

        #expect(result.id == "rd-existing")
        #expect(result.versionId == "v-2")
        #expect(result.contactFirstName == "New")
        #expect(result.contactEmail == "new@example.com")
        #expect(result.notes == "Use staging")
    }
}

private final class ReviewDetailThrowingStub: APIClient, @unchecked Sendable {
    func request<T: Decodable>(_ endpoint: Request<T>) async throws -> T {
        throw URLError(.badServerResponse)
    }
    func request(_ endpoint: Request<Void>) async throws {
        throw URLError(.badServerResponse)
    }
}

/// Throws on the first (GET) request; returns a pre-configured response for subsequent requests.
private final class SequencedGetThrowStub: APIClient, @unchecked Sendable {
    var postResponse: AppStoreReviewDetailResponse?
    private var callCount = 0

    func request<T: Decodable>(_ endpoint: Request<T>) async throws -> T {
        callCount += 1
        if callCount == 1 {
            // Simulate "not found" — the GET for existing detail
            throw URLError(.badServerResponse)
        }
        guard let response = postResponse as? T else {
            fatalError("SequencedGetThrowStub: unexpected type \(T.self)")
        }
        return response
    }

    func request(_ endpoint: Request<Void>) async throws {}
}
