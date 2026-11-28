@preconcurrency import AppStoreConnect_Swift_SDK
import Foundation

// The SDK (4.6.2) doesn't model the age-rating questions `sharedLocation` and
// `datingAndRelationships`, so asc reads and writes them beside the SDK's own types.
// Drop these once the SDK carries both attributes.

/// An age rating declaration response: the SDK's view plus the questions it lacks.
struct AgeRatingDeclarationDocument: Decodable {
    let response: AgeRatingDeclarationResponse
    let sharedLocation: Bool?
    let datingAndRelationships: Bool?

    init(_ response: AgeRatingDeclarationResponse, sharedLocation: Bool? = nil, datingAndRelationships: Bool? = nil) {
        self.response = response
        self.sharedLocation = sharedLocation
        self.datingAndRelationships = datingAndRelationships
    }

    init(from decoder: Decoder) throws {
        response = try AgeRatingDeclarationResponse(from: decoder)
        let answers = try UnmodeledAnswersDocument(from: decoder).data.attributes
        sharedLocation = answers?.sharedLocation
        datingAndRelationships = answers?.datingAndRelationships
    }

    private struct UnmodeledAnswersDocument: Decodable {
        struct Resource: Decodable { let attributes: UnmodeledAnswers? }
        let data: Resource
    }
}

struct UnmodeledAnswers: Codable {
    let sharedLocation: Bool?
    let datingAndRelationships: Bool?
}

/// A PATCH body: the SDK's attributes plus the questions it lacks, in one `attributes` object.
struct AgeRatingDeclarationUpdateBody: Encodable {
    struct Resource: Encodable {
        let type = "ageRatingDeclarations"
        let id: String
        let attributes: Attributes
    }

    struct Attributes: Encodable {
        let sdk: AgeRatingDeclarationUpdateRequest.Data.Attributes
        let unmodeled: UnmodeledAnswers

        func encode(to encoder: Encoder) throws {
            try sdk.encode(to: encoder)
            try unmodeled.encode(to: encoder)
        }
    }

    let data: Resource
}
