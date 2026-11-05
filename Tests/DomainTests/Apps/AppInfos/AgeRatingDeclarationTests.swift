import Testing
@testable import Domain

@Suite
struct AgeRatingDeclarationTests {

    @Test func `ageRatingDeclaration carries appInfoId`() {
        let decl = AgeRatingDeclaration(id: "decl-1", appInfoId: "info-42")
        #expect(decl.appInfoId == "info-42")
    }

    @Test func `ageRatingDeclaration affordances include update command`() {
        let decl = AgeRatingDeclaration(id: "decl-1", appInfoId: "info-42")
        #expect(decl.affordances["update"] == "asc age-rating update --declaration-id decl-1")
    }

    @Test func `ageRatingDeclaration affordances include getAgeRating command`() {
        let decl = AgeRatingDeclaration(id: "decl-1", appInfoId: "info-42")
        #expect(decl.affordances["getAgeRating"] == "asc age-rating get --app-info-id info-42")
    }

    @Test func `ageRatingDeclaration stores boolean content flags`() {
        let decl = AgeRatingDeclaration(
            id: "decl-1",
            appInfoId: "info-1",
            isAdvertising: true,
            isGambling: false,
            isLootBox: true
        )
        #expect(decl.isAdvertising == true)
        #expect(decl.isGambling == false)
        #expect(decl.isLootBox == true)
    }

    @Test func `ageRatingDeclaration stores intensity ratings`() {
        let decl = AgeRatingDeclaration(
            id: "decl-1",
            appInfoId: "info-1",
            profanityOrCrudeHumor: .infrequentOrMild,
            violenceRealistic: .frequentOrIntense
        )
        #expect(decl.violenceRealistic == .frequentOrIntense)
        #expect(decl.profanityOrCrudeHumor == .infrequentOrMild)
    }

    @Test func `ageRatingDeclaration stores override ratings`() {
        let decl = AgeRatingDeclaration(
            id: "decl-1",
            appInfoId: "info-1",
            kidsAgeBand: .nineToEleven,
            ageRatingOverride: .thirteenPlus,
            koreaAgeRatingOverride: .fifteenPlus
        )
        #expect(decl.kidsAgeBand == .nineToEleven)
        #expect(decl.ageRatingOverride == .thirteenPlus)
        #expect(decl.koreaAgeRatingOverride == .fifteenPlus)
    }

    @Test func `should offer every Korea age-rating override App Store Connect accepts`() {
        #expect(KoreaAgeRatingOverride.allCases.map(\.rawValue) == [
            "NONE", "ALL", "TWELVE_PLUS", "FIFTEEN_PLUS", "NINETEEN_PLUS",
        ])
    }

    @Test func `contentIntensity has correct raw values`() {
        #expect(ContentIntensity.none.rawValue == "NONE")
        #expect(ContentIntensity.infrequentOrMild.rawValue == "INFREQUENT_OR_MILD")
        #expect(ContentIntensity.frequentOrIntense.rawValue == "FREQUENT_OR_INTENSE")
        #expect(ContentIntensity.infrequent.rawValue == "INFREQUENT")
        #expect(ContentIntensity.frequent.rawValue == "FREQUENT")
    }

    @Test func `ageRatingOverride has correct raw values`() {
        #expect(AgeRatingOverride.none.rawValue == "NONE")
        #expect(AgeRatingOverride.ninePlus.rawValue == "NINE_PLUS")
        #expect(AgeRatingOverride.thirteenPlus.rawValue == "THIRTEEN_PLUS")
        #expect(AgeRatingOverride.sixteenPlus.rawValue == "SIXTEEN_PLUS")
        #expect(AgeRatingOverride.eighteenPlus.rawValue == "EIGHTEEN_PLUS")
        #expect(AgeRatingOverride.unrated.rawValue == "UNRATED")
    }

    @Test func `kidsAgeBand has correct raw values`() {
        #expect(KidsAgeBand.fiveAndUnder.rawValue == "FIVE_AND_UNDER")
        #expect(KidsAgeBand.sixToEight.rawValue == "SIX_TO_EIGHT")
        #expect(KidsAgeBand.nineToEleven.rawValue == "NINE_TO_ELEVEN")
    }

    @Test func `appInfo affordances include getAgeRating command`() {
        let info = AppInfo(id: "info-1", appId: "app-42")
        #expect(info.affordances["getAgeRating"] == "asc age-rating get --app-info-id info-1")
    }

    // MARK: - Unanswered questions

    /// A declaration with every questionnaire answer, and none of the optional overrides.
    private func answered(socialMedia: Bool? = false, socialMediaAgeRestricted: Bool? = nil, gambling: Bool? = false) -> AgeRatingDeclaration {
        AgeRatingDeclaration(
            id: "decl-1", appInfoId: "info-1",
            isAdvertising: false, isGambling: gambling, isHealthOrWellnessTopics: false, isLootBox: false,
            isMessagingAndChat: false, isParentalControls: false, isAgeAssurance: false,
            isUnrestrictedWebAccess: false, isUserGeneratedContent: false,
            isSocialMedia: socialMedia, isSocialMediaAgeRestricted: socialMediaAgeRestricted,
            alcoholTobaccoOrDrugUseOrReferences: ContentIntensity.none, contests: ContentIntensity.none,
            gamblingSimulated: ContentIntensity.none, gunsOrOtherWeapons: ContentIntensity.none,
            medicalOrTreatmentInformation: ContentIntensity.none, profanityOrCrudeHumor: ContentIntensity.none,
            sexualContentGraphicAndNudity: ContentIntensity.none, sexualContentOrNudity: ContentIntensity.none,
            horrorOrFearThemes: ContentIntensity.none, matureOrSuggestiveThemes: ContentIntensity.none,
            violenceCartoonOrFantasy: ContentIntensity.none, violenceRealisticProlongedGraphicOrSadistic: ContentIntensity.none,
            violenceRealistic: ContentIntensity.none
        )
    }

    @Test func `should have nothing unanswered when every question is answered and the overrides are empty`() {
        #expect(answered().unansweredQuestions == [])
    }

    @Test func `should name social media when it is unanswered`() {
        #expect(answered(socialMedia: nil).unansweredQuestions == ["socialMedia"])
    }

    @Test func `should count an answer of false as answered`() {
        #expect(answered(socialMedia: false, gambling: false).unansweredQuestions == [])
    }

    @Test func `should name every unanswered question`() {
        #expect(answered(socialMedia: nil, gambling: nil).unansweredQuestions == ["gambling", "socialMedia"])
    }

    @Test func `should ask whether social media is age restricted when the app has social media`() {
        #expect(answered(socialMedia: true).unansweredQuestions == ["socialMediaAgeRestricted"])
        #expect(answered(socialMedia: true, socialMediaAgeRestricted: false).unansweredQuestions == [])
    }

    @Test func `should name each question of a blank declaration by its App Store Connect attribute`() {
        #expect(AgeRatingDeclaration(id: "decl-1", appInfoId: "info-1").unansweredQuestions == [
            "advertising", "gambling", "healthOrWellnessTopics", "lootBox", "messagingAndChat",
            "parentalControls", "ageAssurance", "unrestrictedWebAccess", "userGeneratedContent", "socialMedia",
            "alcoholTobaccoOrDrugUseOrReferences", "contests", "gamblingSimulated", "gunsOrOtherWeapons",
            "medicalOrTreatmentInformation", "profanityOrCrudeHumor", "sexualContentGraphicAndNudity",
            "sexualContentOrNudity", "horrorOrFearThemes", "matureOrSuggestiveThemes", "violenceCartoonOrFantasy",
            "violenceRealisticProlongedGraphicOrSadistic", "violenceRealistic",
        ])
    }
}
