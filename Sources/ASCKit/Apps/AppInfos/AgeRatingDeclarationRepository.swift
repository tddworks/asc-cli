import Mockable

@Mockable
public protocol AgeRatingDeclarationRepository: Sendable {
    func getDeclaration(appInfoId: String) async throws -> AgeRatingDeclaration
    func updateDeclaration(id: String, update: AgeRatingDeclarationUpdate) async throws -> AgeRatingDeclaration
}
