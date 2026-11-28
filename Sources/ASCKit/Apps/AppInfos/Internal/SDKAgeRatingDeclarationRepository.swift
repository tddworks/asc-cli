@preconcurrency import AppStoreConnect_Swift_SDK
import Foundation

public struct SDKAgeRatingDeclarationRepository: AgeRatingDeclarationRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func getDeclaration(appInfoId: String) async throws -> ASCKit.AgeRatingDeclaration {
        let sdk = APIEndpoint.v1.appInfos.id(appInfoId).ageRatingDeclaration.get()
        let document = try await client.request(Request<AgeRatingDeclarationDocument>(
            path: sdk.path, method: "GET", query: sdk.query, id: "appInfos_ageRatingDeclaration_getToOneRelated"
        ))
        return mapDeclaration(document, appInfoId: appInfoId)
    }

    public func updateDeclaration(id: String, update: ASCKit.AgeRatingDeclarationUpdate) async throws -> ASCKit.AgeRatingDeclaration {
        let body = AgeRatingDeclarationUpdateBody(data: .init(
            id: id,
            attributes: .init(
                sdk: mapUpdateAttributes(update),
                unmodeled: UnmodeledAnswers(
                    sharedLocation: update.isSharedLocation,
                    datingAndRelationships: update.isDatingAndRelationships
                )
            )
        ))
        let document = try await client.request(Request<AgeRatingDeclarationDocument>(
            path: "/v1/ageRatingDeclarations/\(id)", method: "PATCH", body: body, id: "ageRatingDeclarations_updateInstance"
        ))
        return mapDeclaration(document, appInfoId: "")
    }

    // MARK: - Mappers

    private func mapDeclaration(
        _ document: AgeRatingDeclarationDocument,
        appInfoId: String
    ) -> ASCKit.AgeRatingDeclaration {
        let sdk = document.response.data
        let a = sdk.attributes
        return ASCKit.AgeRatingDeclaration(
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
            isSocialMedia: a?.isSocialMedia,
            isSocialMediaAgeRestricted: a?.isSocialMediaAgeRestricted,
            isSharedLocation: document.sharedLocation,
            isDatingAndRelationships: document.datingAndRelationships,
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
            kidsAgeBand: a?.kidsAgeBand.flatMap { ASCKit.KidsAgeBand(rawValue: $0.rawValue) },
            ageRatingOverride: a?.ageRatingOverrideV2.flatMap { ASCKit.AgeRatingOverride(rawValue: $0.rawValue) },
            koreaAgeRatingOverride: a?.koreaAgeRatingOverride.flatMap { ASCKit.KoreaAgeRatingOverride(rawValue: $0.rawValue) },
            gracRatingClassificationNumber: a?.gracRatingClassificationNumber,
            developerAgeRatingInfoUrl: a?.developerAgeRatingInfoURL?.absoluteString
        )
    }

    private func mapIntensity<T: RawRepresentable>(_ value: T?) -> ASCKit.ContentIntensity? where T.RawValue == String {
        guard let value else { return nil }
        return ASCKit.ContentIntensity(rawValue: value.rawValue)
    }

    private func mapUpdateAttributes(
        _ update: ASCKit.AgeRatingDeclarationUpdate
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
            isSocialMedia: update.isSocialMedia,
            isSocialMediaAgeRestricted: update.isSocialMediaAgeRestricted,
            horrorOrFearThemes: update.horrorOrFearThemes.flatMap { .init(rawValue: $0.rawValue) },
            matureOrSuggestiveThemes: update.matureOrSuggestiveThemes.flatMap { .init(rawValue: $0.rawValue) },
            isUnrestrictedWebAccess: update.isUnrestrictedWebAccess,
            isUserGeneratedContent: update.isUserGeneratedContent,
            violenceCartoonOrFantasy: update.violenceCartoonOrFantasy.flatMap { .init(rawValue: $0.rawValue) },
            violenceRealisticProlongedGraphicOrSadistic: update.violenceRealisticProlongedGraphicOrSadistic
                .flatMap { .init(rawValue: $0.rawValue) },
            violenceRealistic: update.violenceRealistic.flatMap { .init(rawValue: $0.rawValue) },
            ageRatingOverrideV2: update.ageRatingOverride.flatMap { .init(rawValue: $0.rawValue) },
            koreaAgeRatingOverride: update.koreaAgeRatingOverride.flatMap { .init(rawValue: $0.rawValue) },
            gracRatingClassificationNumber: update.gracRatingClassificationNumber,
            developerAgeRatingInfoURL: update.developerAgeRatingInfoUrl.flatMap(URL.init(string:))
        )
    }
}
