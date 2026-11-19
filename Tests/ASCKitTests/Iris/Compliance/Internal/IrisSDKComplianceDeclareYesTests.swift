import Foundation
import Mockable
import Testing
@testable import ASCKit

/// Apple's two forms as captured (docs/features/app-compliance/design.md): each metadata
/// post answers with the fields the answers so far open.
private enum CapturedForms {
    static let files = #"[".doc",".docx",".jpeg",".jpg",".pdf",".png"]"#

    static func constraint(_ id: String, _ type: String, form: String, slug: String, files: Bool = false) -> String {
        #""\#(id)": { "presentation": { "id": "\#(id)", "inputType": "\#(type)", "label": "PPM.compliance.form.\#(form).field.\#(slug).label" }, "validation": { "required": true, "editable": true\#(files ? #", "allowedFileTypes": \#(Self.files)"# : "") } }"#
    }

    /// The Security Assessment form for a draft.
    static func securityAssessment(_ draft: [String: String]) -> String {
        var fields = [constraint("field-1", "RADIO", form: "SECURITYASF395E", slug: "doesyourap2852f")]
        if draft["field-1"] == "YES" {
            fields.append(constraint("field-2", "FILE", form: "SECURITYASF395E", slug: "proofofacocb097", files: true))
            fields.append(constraint("field-3", "FILE", form: "SECURITYASF395E", slug: "securityascf4ff1", files: true))
        }
        return #"{ "formName": "SECURITYASF395E", "constraints": { \#(fields.joined(separator: ", ")) } }"#
    }

    /// The AIGC form for a draft: a tree, each pick opening its branch.
    static func aiGeneratedContent(_ draft: [String: String]) -> String {
        let form = "AIGENERATEFD1DE"
        var fields = [constraint("aigc-offers", "RADIO", form: form, slug: "doesyourap268df2")]
        if draft["aigc-offers"] == "YES" {
            fields.append(constraint("filing-type", "RADIO", form: form, slug: "whichfilinc6deb2"))
            fields.append(constraint("third-party", "RADIO", form: form, slug: "areyourappd75c12"))
            if draft["filing-type"] == "LARGE" {
                fields.append(constraint("llm-name", "TEXT", form: form, slug: "llmname2"))
                fields.append(constraint("llm-filing", "TEXT", form: form, slug: "llmfilingnumber4"))
            }
            if draft["filing-type"] == "ALGOR" {
                fields.append(constraint("algorithm-name", "TEXT", form: form, slug: "algorithmname2"))
                fields.append(constraint("algorithm-filing", "TEXT", form: form, slug: "algorithmf737252"))
            }
            if draft["third-party"] == "YES" {
                fields.append(constraint("authorization", "FILE", form: form, slug: "authorizat9286a3", files: true))
            }
        }
        return #"{ "formName": "\#(form)", "constraints": { \#(fields.joined(separator: ", ")) } }"#
    }

    /// The draft a metadata post carries: each field's `sValue`, or "FILE" for an attached file.
    static func draft(of body: Data) -> [String: String] {
        let json = (try? JSONSerialization.jsonObject(with: body)) as? [String: Any]
        let fields = ((json?["form"] as? [String: Any])?["fields"] as? [[String: Any]]) ?? []
        return Dictionary(uniqueKeysWithValues: fields.map { ($0["id"] as! String, ($0["sValue"] as? String) ?? "FILE") })
    }
}

@Suite
struct IrisSDKComplianceDeclareYesTests {
    private let session = IrisSession(cookies: "myacinfo=a")
    private let entity = "accounts/team-uuid/entities/1234567890"

    private func ok(_ json: String) -> (Data, HTTPURLResponse) {
        (Data(json.utf8), HTTPURLResponse(url: URL(string: "https://appstoreconnect.apple.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }

    private func accounts() -> MockAppStoreConnectAccounts {
        let accounts = MockAppStoreConnectAccounts()
        given(accounts).fetchSession(cookies: .any)
            .willReturn(OlympusClient.OlympusSession(providerID: 42, teamId: "team-uuid", userEmail: "dev@example.com"))
        return accounts
    }

    private func apple(requirementId: String, form: @escaping @Sendable ([String: String]) -> String) -> MockIrisAPI {
        let api = MockIrisAPI()
        given(api).compliancePost(path: .value("\(entity)/requirements/\(requirementId)/metadata"), body: .any, cookies: .any)
            .willProduce { _, body, _ in self.ok(form(CapturedForms.draft(of: body))) }
        given(api).compliancePost(path: .value("\(entity)/forms"), body: .any, cookies: .any)
            .willReturn(ok(#"{ "data": { "id": "form-9", "requirementId": "\#(requirementId)", "formName": "X", "fields": [], "status": "COLLECTED_VERIFY_PENDING" } }"#))
        given(api).complianceGet(path: .any, queryItems: .any, cookies: .any).willReturn(ok(#"{ "data": [] }"#))
        return api
    }

    private func requirement(_ id: String, _ kind: ComplianceKind) -> ComplianceRequirement {
        ComplianceRequirement(id: id, appId: "1234567890", kind: kind, regions: ["CHN"], isRequired: true,
                              status: .missingInfo, updatedAt: nil, requiredActions: [], declaration: nil)
    }

    private func savedBody(_ api: MockIrisAPI, requirementId: String, fields: String) {
        verify(api).compliancePost(
            path: .value("\(entity)/forms"),
            body: .value(Data(#"{"accountId":"team-uuid","entityId":"1234567890","fields":[\#(fields)],"requirementId":"\#(requirementId)"}"#.utf8)),
            cookies: .any
        ).called(1)
    }

    @Test func `should send a Security Assessment Yes with both files inside the declaration`() async throws {
        let api = apple(requirementId: "req-1", form: CapturedForms.securityAssessment)
        let answer = ComplianceAnswer.offered(.securityAssessment(
            proof: ComplianceFile(name: "proof.png", data: Data("P".utf8)),
            report: ComplianceFile(name: "report.pdf", data: Data("R".utf8))
        ))

        _ = try await IrisSDKComplianceRepository(api: api, accounts: accounts())
            .declare(session: session, requirement: requirement("req-1", .securityAssessment), answer: answer)

        savedBody(api, requirementId: "req-1", fields: [
            #"{"id":"field-1","sValue":"YES"}"#,
            #"{"fileContent":{"fileData":"UA==","fileName":"proof.png","fileType":"image/png"},"id":"field-2"}"#,
            #"{"fileContent":{"fileData":"Ug==","fileName":"report.pdf","fileType":"application/pdf"},"id":"field-3"}"#,
        ].joined(separator: ","))
    }

    @Test func `should walk the AIGC form one answer at a time and send every field it opened`() async throws {
        let api = apple(requirementId: "req-2", form: CapturedForms.aiGeneratedContent)
        let answer = ComplianceAnswer.offered(.aiGeneratedContent(
            filing: .largeLanguageModel(name: "Example Model", filingNumber: "Example-0000"),
            thirdParty: .used(authorization: ComplianceFile(name: "agreement.pdf", data: Data("A".utf8)))
        ))

        _ = try await IrisSDKComplianceRepository(api: api, accounts: accounts())
            .declare(session: session, requirement: requirement("req-2", .aiGeneratedContent), answer: answer)

        savedBody(api, requirementId: "req-2", fields: [
            #"{"id":"aigc-offers","sValue":"YES"}"#,
            #"{"id":"filing-type","sValue":"LARGE"}"#,
            #"{"id":"third-party","sValue":"YES"}"#,
            #"{"fileContent":{"fileData":"QQ==","fileName":"agreement.pdf","fileType":"application/pdf"},"id":"authorization"}"#,
            #"{"id":"llm-filing","sValue":"Example-0000"}"#,
            #"{"id":"llm-name","sValue":"Example Model"}"#,
        ].joined(separator: ","))
    }

    @Test func `should send an algorithm filing without third-party technology`() async throws {
        let api = apple(requirementId: "req-2", form: CapturedForms.aiGeneratedContent)
        let answer = ComplianceAnswer.offered(.aiGeneratedContent(
            filing: .algorithm(name: "Recommender", filingNumber: "Algo-1"), thirdParty: .none
        ))

        _ = try await IrisSDKComplianceRepository(api: api, accounts: accounts())
            .declare(session: session, requirement: requirement("req-2", .aiGeneratedContent), answer: answer)

        savedBody(api, requirementId: "req-2", fields: [
            #"{"id":"aigc-offers","sValue":"YES"}"#,
            #"{"id":"filing-type","sValue":"ALGOR"}"#,
            #"{"id":"third-party","sValue":"NO"}"#,
            #"{"id":"algorithm-filing","sValue":"Algo-1"}"#,
            #"{"id":"algorithm-name","sValue":"Recommender"}"#,
        ].joined(separator: ","))
    }

    @Test func `should refuse a file type the form doesn't accept, without saving`() async {
        let api = apple(requirementId: "req-1", form: CapturedForms.securityAssessment)
        let answer = ComplianceAnswer.offered(.securityAssessment(
            proof: ComplianceFile(name: "proof.zip", data: Data("P".utf8)),
            report: ComplianceFile(name: "report.pdf", data: Data("R".utf8))
        ))

        await #expect(throws: ComplianceError.fileTypeNotAllowed(fileName: "proof.zip", allowed: [".doc", ".docx", ".jpeg", ".jpg", ".pdf", ".png"])) {
            try await IrisSDKComplianceRepository(api: api, accounts: accounts())
                .declare(session: session, requirement: requirement("req-1", .securityAssessment), answer: answer)
        }
        verify(api).compliancePost(path: .value("\(entity)/forms"), body: .any, cookies: .any).called(0)
    }

    @Test func `should refuse a form that asks for something asc can't answer, without saving`() async {
        let api = apple(requirementId: "req-1") { draft in
            var form = CapturedForms.securityAssessment(draft)
            if draft["field-1"] == "YES" {
                form = form.replacingOccurrences(of: "proofofacocb097", with: "businesslic0001")
            }
            return form
        }
        let answer = ComplianceAnswer.offered(.securityAssessment(
            proof: ComplianceFile(name: "proof.png", data: Data()), report: ComplianceFile(name: "report.pdf", data: Data())
        ))

        await #expect(throws: ComplianceError.formNotUnderstood(kind: .securityAssessment, field: "businesslic0001")) {
            try await IrisSDKComplianceRepository(api: api, accounts: accounts())
                .declare(session: session, requirement: requirement("req-1", .securityAssessment), answer: answer)
        }
        verify(api).compliancePost(path: .value("\(entity)/forms"), body: .any, cookies: .any).called(0)
    }

    @Test func `should explain a refused file and a form it doesn't understand`() {
        #expect(ComplianceError.fileTypeNotAllowed(fileName: "proof.zip", allowed: [".pdf", ".png"]).description
            == "proof.zip can't be sent: this field takes .pdf, .png.")
        #expect(ComplianceError.formNotUnderstood(kind: .securityAssessment, field: "businesslic0001").description
            == "Apple's Security Assessment form asks for something asc doesn't know (businesslic0001). Answer it on the App Compliance page.")
    }
}
