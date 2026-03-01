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
}
