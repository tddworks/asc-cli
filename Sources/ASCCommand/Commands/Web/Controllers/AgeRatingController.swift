import Domain
import Foundation
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return `AgeRatingDeclaration` resources.
struct AgeRatingController: Sendable {
    let repo: any AgeRatingDeclarationRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        // Canonical nested path matches the resolver's `_links.getAgeRating`.
        group.get("/app-infos/:appInfoId/age-rating") { _, context -> Response in
            guard let appInfoId = context.parameters.get("appInfoId") else { return jsonError("Missing appInfoId") }
            let declaration = try await self.repo.getDeclaration(appInfoId: appInfoId)
            return try restFormat(declaration)
        }

        // Back-compat: the original flat path. Both interpret the param as appInfoId.
        group.get("/age-rating/:id") { _, context -> Response in
            guard let appInfoId = context.parameters.get("id") else { return jsonError("Missing appInfoId") }
            let declaration = try await self.repo.getDeclaration(appInfoId: appInfoId)
            return try restFormat(declaration)
        }

        group.patch("/age-rating/:id") { request, context -> Response in
            guard let declarationId = context.parameters.get("id") else { return jsonError("Missing declarationId") }
            let body = try await request.body.collect(upTo: 64 * 1024)
            let json = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            var update = AgeRatingDeclarationUpdate()
            update.isAdvertising = json["isAdvertising"] as? Bool
            update.isGambling = json["isGambling"] as? Bool
            update.isHealthOrWellnessTopics = json["isHealthOrWellnessTopics"] as? Bool
            update.isLootBox = json["isLootBox"] as? Bool
            update.isMessagingAndChat = json["isMessagingAndChat"] as? Bool
            update.isParentalControls = json["isParentalControls"] as? Bool
            update.isAgeAssurance = json["isAgeAssurance"] as? Bool
            update.isUnrestrictedWebAccess = json["isUnrestrictedWebAccess"] as? Bool
            update.isUserGeneratedContent = json["isUserGeneratedContent"] as? Bool
            update.alcoholTobaccoOrDrugUseOrReferences = (json["alcoholTobaccoOrDrugUseOrReferences"] as? String).flatMap(ContentIntensity.init(rawValue:))
            update.contests = (json["contests"] as? String).flatMap(ContentIntensity.init(rawValue:))
            update.gamblingSimulated = (json["gamblingSimulated"] as? String).flatMap(ContentIntensity.init(rawValue:))
            update.gunsOrOtherWeapons = (json["gunsOrOtherWeapons"] as? String).flatMap(ContentIntensity.init(rawValue:))
            update.medicalOrTreatmentInformation = (json["medicalOrTreatmentInformation"] as? String).flatMap(ContentIntensity.init(rawValue:))
            update.profanityOrCrudeHumor = (json["profanityOrCrudeHumor"] as? String).flatMap(ContentIntensity.init(rawValue:))
            update.sexualContentGraphicAndNudity = (json["sexualContentGraphicAndNudity"] as? String).flatMap(ContentIntensity.init(rawValue:))
            update.sexualContentOrNudity = (json["sexualContentOrNudity"] as? String).flatMap(ContentIntensity.init(rawValue:))
            update.horrorOrFearThemes = (json["horrorOrFearThemes"] as? String).flatMap(ContentIntensity.init(rawValue:))
            update.matureOrSuggestiveThemes = (json["matureOrSuggestiveThemes"] as? String).flatMap(ContentIntensity.init(rawValue:))
            update.violenceCartoonOrFantasy = (json["violenceCartoonOrFantasy"] as? String).flatMap(ContentIntensity.init(rawValue:))
            update.violenceRealisticProlongedGraphicOrSadistic = (json["violenceRealisticProlongedGraphicOrSadistic"] as? String).flatMap(ContentIntensity.init(rawValue:))
            update.violenceRealistic = (json["violenceRealistic"] as? String).flatMap(ContentIntensity.init(rawValue:))
            update.kidsAgeBand = (json["kidsAgeBand"] as? String).flatMap(KidsAgeBand.init(rawValue:))
            update.ageRatingOverride = (json["ageRatingOverride"] as? String).flatMap(AgeRatingOverride.init(rawValue:))
            update.koreaAgeRatingOverride = (json["koreaAgeRatingOverride"] as? String).flatMap(KoreaAgeRatingOverride.init(rawValue:))
            let updated = try await self.repo.updateDeclaration(id: declarationId, update: update)
            return try restFormat(updated)
        }
    }
}
