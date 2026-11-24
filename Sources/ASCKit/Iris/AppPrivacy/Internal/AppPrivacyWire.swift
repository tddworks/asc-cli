/// The App Privacy shapes iris sends and takes (docs/features/app-privacy/design.md).

struct IrisReference: Codable {
    let type: String
    let id: String
}

struct IrisRelationship: Codable {
    let data: IrisReference?
}

/// `GET apps/{id}/dataUsages`: the ids are in the relationships; `included` adds nothing asc reads.
struct AppDataUsagesResponse: Decodable {
    struct Row: Decodable {
        struct Relationships: Decodable {
            let category: IrisRelationship?
            let purpose: IrisRelationship?
            let dataProtection: IrisRelationship?
        }

        let id: String
        let relationships: Relationships
    }

    let data: [Row]
}

/// `GET apps/{id}/dataUsagePublishState`.
struct AppDataUsagesPublishStateResponse: Decodable {
    struct State: Decodable {
        struct Attributes: Decodable {
            let published: Bool?
            let lastPublished: String?
        }

        let attributes: Attributes
    }

    let data: State
}

/// `POST appDataUsages`: the app plus each part of the row it has.
struct AppDataUsageCreateRequest: Encodable {
    struct Resource: Encodable {
        let type = "appDataUsages"
        let relationships: [String: IrisRelationship]
    }

    let data: Resource

    init(appId: String, entry: DataUsageEntry) {
        var relationships = [
            "app": IrisRelationship(data: IrisReference(type: "apps", id: appId)),
            "dataProtection": IrisRelationship(data: IrisReference(type: "appDataUsageDataProtections", id: entry.protection.rawValue)),
        ]
        if let category = entry.category {
            relationships["category"] = IrisRelationship(data: IrisReference(type: "appDataUsageCategories", id: category.rawValue))
        }
        if let purpose = entry.purpose {
            relationships["purpose"] = IrisRelationship(data: IrisReference(type: "appDataUsagePurposes", id: purpose.rawValue))
        }
        data = Resource(relationships: relationships)
    }
}

/// `PATCH appDataUsagesPublishState/{appId}`.
struct AppDataUsagesPublishRequest: Encodable {
    struct Resource: Encodable {
        struct Attributes: Encodable {
            let published: Bool
        }

        let type = "appDataUsagesPublishState"
        let id: String
        let attributes: Attributes
    }

    let data: Resource

    init(appId: String) {
        data = Resource(id: appId, attributes: .init(published: true))
    }
}
