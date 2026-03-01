@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKAgeRatingDeclarationRepository: AgeRatingDeclarationRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func getDeclaration(appInfoId: String) async throws -> Domain.AgeRatingDeclaration {
        let request = APIEndpoint.v1.appInfos.id(appInfoId).ageRatingDeclaration.get()
        let response = try await client.request(request)
        return mapDeclaration(response.data, appInfoId: appInfoId)
    }

    public func updateDeclaration(id: String, update: Domain.AgeRatingDeclarationUpdate) async throws -> Domain.AgeRatingDeclaration {
        let body = AgeRatingDeclarationUpdateRequest(
            data: .init(
                type: .ageRatingDeclarations,
                id: id,
                attributes: mapUpdateAttributes(update)
            )
        )
        let request = APIEndpoint.v1.ageRatingDeclarations.id(id).patch(body)
        let response = try await client.request(request)
        return mapDeclaration(response.data, appInfoId: "")
    }

    // MARK: - Mappers

    private func mapDeclaration(
        _ sdk: AppStoreConnect_Swift_SDK.AgeRatingDeclaration,
        appInfoId: String
    ) -> Domain.AgeRatingDeclaration {
        let a = sdk.attributes
        return Domain.AgeRatingDeclaration(
            id: sdk.id,
            appInfoId: appInfoId,
            isAdvertising: a?.isAdvertising,
            isGambling: a?.isGambling,
            isHealthOrWellnessTopics: a?.isHealthOrWellnessTopics,
            isLootBox: a?.isLootBox,
            isMessagingAndChat: a?.isMessagingAndChat,
            isParentalControls: a?.isParentalControls,
            isAgeAssurance: a?.isAgeAssurance,
            isUnrestrictedWebAccess: a?.isUnrestrictedWebAccess,
            isUserGeneratedContent: a?.isUserGeneratedContent,
            alcoholTobaccoOrDrugUseOrReferences: mapIntensity(a?.alcoholTobaccoOrDrugUseOrReferences),
            contests: mapIntensity(a?.contests),
            gamblingSimulated: mapIntensity(a?.gamblingSimulated),
            gunsOrOtherWeapons: mapIntensity(a?.gunsOrOtherWeapons),
            medicalOrTreatmentInformation: mapIntensity(a?.medicalOrTreatmentInformation),
            profanityOrCrudeHumor: mapIntensity(a?.profanityOrCrudeHumor),
            sexualContentGraphicAndNudity: mapIntensity(a?.sexualContentGraphicAndNudity),
            sexualContentOrNudity: mapIntensity(a?.sexualContentOrNudity),
            horrorOrFearThemes: mapIntensity(a?.horrorOrFearThemes),
            matureOrSuggestiveThemes: mapIntensity(a?.matureOrSuggestiveThemes),
            violenceCartoonOrFantasy: mapIntensity(a?.violenceCartoonOrFantasy),
            violenceRealisticProlongedGraphicOrSadistic: mapIntensity(a?.violenceRealisticProlongedGraphicOrSadistic),
            violenceRealistic: mapIntensity(a?.violenceRealistic),
            kidsAgeBand: a?.kidsAgeBand.flatMap { Domain.KidsAgeBand(rawValue: $0.rawValue) },
            ageRatingOverride: a?.ageRatingOverrideV2.flatMap { Domain.AgeRatingOverride(rawValue: $0.rawValue) },
            koreaAgeRatingOverride: a?.koreaAgeRatingOverride.flatMap { Domain.KoreaAgeRatingOverride(rawValue: $0.rawValue) }
        )
    }

    private func mapIntensity<T: RawRepresentable>(_ value: T?) -> Domain.ContentIntensity? where T.RawValue == String {
        guard let value else { return nil }
        return Domain.ContentIntensity(rawValue: value.rawValue)
    }

    private func mapUpdateAttributes(
        _ update: Domain.AgeRatingDeclarationUpdate
    ) -> AgeRatingDeclarationUpdateRequest.Data.Attributes {
        .init(
            isAdvertising: update.isAdvertising,
            alcoholTobaccoOrDrugUseOrReferences: update.alcoholTobaccoOrDrugUseOrReferences
                .flatMap { .init(rawValue: $0.rawValue) },
            contests: update.contests.flatMap { .init(rawValue: $0.rawValue) },
            isGambling: update.isGambling,
            gamblingSimulated: update.gamblingSimulated.flatMap { .init(rawValue: $0.rawValue) },
            gunsOrOtherWeapons: update.gunsOrOtherWeapons.flatMap { .init(rawValue: $0.rawValue) },
            isHealthOrWellnessTopics: update.isHealthOrWellnessTopics,
            kidsAgeBand: update.kidsAgeBand.flatMap { AppStoreConnect_Swift_SDK.KidsAgeBand(rawValue: $0.rawValue) },
            isLootBox: update.isLootBox,
            medicalOrTreatmentInformation: update.medicalOrTreatmentInformation
                .flatMap { .init(rawValue: $0.rawValue) },
            isMessagingAndChat: update.isMessagingAndChat,
            isParentalControls: update.isParentalControls,
            profanityOrCrudeHumor: update.profanityOrCrudeHumor.flatMap { .init(rawValue: $0.rawValue) },
            isAgeAssurance: update.isAgeAssurance,
            sexualContentGraphicAndNudity: update.sexualContentGraphicAndNudity
                .flatMap { .init(rawValue: $0.rawValue) },
            sexualContentOrNudity: update.sexualContentOrNudity.flatMap { .init(rawValue: $0.rawValue) },
            horrorOrFearThemes: update.horrorOrFearThemes.flatMap { .init(rawValue: $0.rawValue) },
            matureOrSuggestiveThemes: update.matureOrSuggestiveThemes.flatMap { .init(rawValue: $0.rawValue) },
            isUnrestrictedWebAccess: update.isUnrestrictedWebAccess,
            isUserGeneratedContent: update.isUserGeneratedContent,
            violenceCartoonOrFantasy: update.violenceCartoonOrFantasy.flatMap { .init(rawValue: $0.rawValue) },
            violenceRealisticProlongedGraphicOrSadistic: update.violenceRealisticProlongedGraphicOrSadistic
                .flatMap { .init(rawValue: $0.rawValue) },
            violenceRealistic: update.violenceRealistic.flatMap { .init(rawValue: $0.rawValue) },
            ageRatingOverrideV2: update.ageRatingOverride.flatMap { .init(rawValue: $0.rawValue) },
            koreaAgeRatingOverride: update.koreaAgeRatingOverride.flatMap { .init(rawValue: $0.rawValue) }
        )
    }
}
