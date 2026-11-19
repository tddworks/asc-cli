import Foundation
import Mockable
import Testing
@testable import ASCKit

/// Fixtures are the captured responses in docs/features/app-compliance/design.md, ids replaced.
@Suite
struct IrisSDKComplianceRepositoryTests {
    private let session = IrisSession(cookies: "myacinfo=a")

    private func ok(_ json: String) -> (Data, HTTPURLResponse) {
        (Data(json.utf8), HTTPURLResponse(url: URL(string: "https://appstoreconnect.apple.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }

    private func signedInTo(team: String?) -> MockAppStoreConnectAccounts {
        let accounts = MockAppStoreConnectAccounts()
        given(accounts).fetchSession(cookies: .value("myacinfo=a"))
            .willReturn(OlympusClient.OlympusSession(providerID: 42, teamId: team, userEmail: "dev@example.com"))
        return accounts
    }

    private func iris(requirements: String, forms: String) -> MockIrisAPI {
        let api = MockIrisAPI()
        given(api).complianceGet(
            path: .value("accounts/team-uuid/requirements"),
            queryItems: .value([URLQueryItem(name: "entity_id", value: "1234567890")]),
            cookies: .value("myacinfo=a")
        ).willReturn(ok(requirements))
        given(api).complianceGet(
            path: .value("accounts/team-uuid/entities/1234567890/forms"), queryItems: .value([]), cookies: .value("myacinfo=a")
        ).willReturn(ok(forms))
        return api
    }

    private let unanswered = #"""
    { "data": [
      { "id": "req-1", "formName": "SECURITYASF395E", "entityId": "1234567890", "entityType": "APP",
        "status": "PENDING_COLLECT", "isRequired": true, "countries": [ "CHN" ] },
      { "id": "req-2", "formName": "AIGENERATEFD1DE", "entityId": "1234567890", "entityType": "APP",
        "status": "PENDING_COLLECT", "isRequired": true, "countries": [ "CHN" ] }
    ] }
    """#

    @Test func `should list every requirement nobody has answered as Missing Info`() async throws {
        let repo = IrisSDKComplianceRepository(api: iris(requirements: unanswered, forms: #"{ "data": [] }"#), accounts: signedInTo(team: "team-uuid"))

        let rows = try await repo.listRequirements(session: session, appId: "1234567890")

        #expect(rows == [
            ComplianceRequirement(id: "req-1", appId: "1234567890", kind: .securityAssessment, regions: ["CHN"], isRequired: true,
                                  status: .missingInfo, updatedAt: nil, requiredActions: [], declaration: nil),
            ComplianceRequirement(id: "req-2", appId: "1234567890", kind: .aiGeneratedContent, regions: ["CHN"], isRequired: true,
                                  status: .missingInfo, updatedAt: nil, requiredActions: [], declaration: nil),
        ])
    }

    @Test func `should attach each declaration to the requirement it answers`() async throws {
        let requirements = #"""
        { "data": [
          { "id": "req-1", "formName": "SECURITYASF395E", "entityId": "1234567890", "entityType": "APP",
            "status": "COLLECTED_VERIFY_PENDING", "isRequired": true, "countries": [ "CHN" ], "formId": "form-1",
            "dateSigned": "2026-01-01T00:00:00.000Z", "lastUpdatedDate": "2026-01-02T00:00:00.000Z",
            "requiredActions": [ "APP_BINARY_SUBMISSION" ] },
          { "id": "req-2", "formName": "AIGENERATEFD1DE", "entityId": "1234567890", "entityType": "APP",
            "status": "COLLECTED_VERIFY_NOT_NECESSARY", "isRequired": true, "countries": [ "CHN" ], "formId": "form-2",
            "dateSigned": "2026-01-03T00:00:00.000Z", "lastUpdatedDate": "2026-01-03T00:00:00.000Z" }
        ] }
        """#
        let forms = #"""
        { "data": [
          { "id": "form-2", "requirementId": "req-2", "formName": "AIGENERATEFD1DE",
            "fields": [ { "id": "aigc-offers", "sValue": "NO", "verificationStatus": "FIELD_VERIFY_NOT_NECESSARY" } ],
            "status": "COLLECTED_VERIFY_NOT_NECESSARY", "createdAt": "1790000000000", "updatedAt": "1790000000000" },
          { "id": "form-1", "requirementId": "req-1", "formName": "SECURITYASF395E",
            "fields": [
              { "id": "field-1", "sValue": "YES", "verificationStatus": "FIELD_VERIFY_NOT_NECESSARY" },
              { "id": "field-2", "verificationStatus": "FIELD_VERIFY_PENDING",
                "fileContent": { "fileId": "file-1", "fileName": "proof.png", "fileType": "image/png", "fileSizeBytes": "34188" } }
            ],
            "status": "COLLECTED_VERIFY_PENDING", "createdAt": "1790000000000", "updatedAt": "1790000000000" }
        ] }
        """#
        let repo = IrisSDKComplianceRepository(api: iris(requirements: requirements, forms: forms), accounts: signedInTo(team: "team-uuid"))

        let rows = try await repo.listRequirements(session: session, appId: "1234567890")

        #expect(rows == [
            ComplianceRequirement(id: "req-1", appId: "1234567890", kind: .securityAssessment, regions: ["CHN"], isRequired: true,
                                  status: .pendingVerification, updatedAt: "2026-01-02T00:00:00.000Z",
                                  requiredActions: [.appBinarySubmission], declaration: ComplianceDeclaration(id: "form-1", answer: .yes)),
            ComplianceRequirement(id: "req-2", appId: "1234567890", kind: .aiGeneratedContent, regions: ["CHN"], isRequired: true,
                                  status: .active, updatedAt: "2026-01-03T00:00:00.000Z",
                                  requiredActions: [], declaration: ComplianceDeclaration(id: "form-2", answer: .no)),
        ])
    }

    @Test func `should keep a compliance and a status it doesn't know`() async throws {
        let requirements = #"""
        { "data": [ { "id": "req-9", "formName": "MEDICALDEV0001", "entityId": "1234567890", "entityType": "APP",
                      "status": "COLLECTED_VERIFY_REJECTED", "isRequired": false, "countries": [ "CHN", "HKG" ] } ] }
        """#
        let repo = IrisSDKComplianceRepository(api: iris(requirements: requirements, forms: #"{ "data": [] }"#), accounts: signedInTo(team: "team-uuid"))

        let rows = try await repo.listRequirements(session: session, appId: "1234567890")

        #expect(rows == [
            ComplianceRequirement(id: "req-9", appId: "1234567890", kind: .unrecognized(formName: "MEDICALDEV0001"),
                                  regions: ["CHN", "HKG"], isRequired: false,
                                  status: .unrecognized(wireValue: "COLLECTED_VERIFY_REJECTED"),
                                  updatedAt: nil, requiredActions: [], declaration: nil),
        ])
    }

    @Test func `should keep a declaration no requirement lists, as a row it won't declare`() async throws {
        let forms = #"""
        { "data": [ { "id": "form-7", "requirementId": "req-7", "formName": "SECURITYASF395E",
                      "fields": [ { "id": "field-1", "sValue": "NO" } ], "status": "COLLECTED_VERIFY_NOT_NECESSARY" } ] }
        """#
        let repo = IrisSDKComplianceRepository(api: iris(requirements: #"{ "data": [] }"#, forms: forms), accounts: signedInTo(team: "team-uuid"))

        let rows = try await repo.listRequirements(session: session, appId: "1234567890")

        #expect(rows == [
            ComplianceRequirement(id: "req-7", appId: "1234567890", kind: .unrecognized(formName: "SECURITYASF395E"),
                                  regions: [], isRequired: false, status: .active, updatedAt: nil, requiredActions: [],
                                  declaration: ComplianceDeclaration(id: "form-7", answer: .no)),
        ])
        #expect(rows[0].isDeclarable == false)
    }

    @Test func `should refuse to list when the session names no team`() async {
        let repo = IrisSDKComplianceRepository(api: MockIrisAPI(), accounts: signedInTo(team: nil))

        await #expect(throws: ComplianceError.teamUnknown) {
            try await repo.listRequirements(session: session, appId: "1234567890")
        }
    }
}

/// `declare` with a No, against the captured metadata and save calls.
@Suite
struct IrisSDKComplianceDeclareTests {
    private let session = IrisSession(cookies: "myacinfo=a")
    private let forms = "accounts/team-uuid/entities/1234567890/forms"
    private let metadata = "accounts/team-uuid/entities/1234567890/requirements/req-1/metadata"

    private func reply(_ status: Int, _ json: String) -> (Data, HTTPURLResponse) {
        (Data(json.utf8), HTTPURLResponse(url: URL(string: "https://appstoreconnect.apple.com")!, statusCode: status, httpVersion: nil, headerFields: nil)!)
    }

    private func accounts() -> MockAppStoreConnectAccounts {
        let accounts = MockAppStoreConnectAccounts()
        given(accounts).fetchSession(cookies: .any)
            .willReturn(OlympusClient.OlympusSession(providerID: 42, teamId: "team-uuid", userEmail: "dev@example.com"))
        return accounts
    }

    /// The Security Assessment question, as the metadata gives it; `editable` only when Apple allows a change.
    private func question(editable: Bool) -> String {
        #"""
        { "formName": "SECURITYASF395E", "formMode": "MODAL", "form": {},
          "constraints": { "field-1": {
            "presentation": { "id": "field-1", "inputType": "RADIO",
              "label": "PPM.compliance.form.SECURITYASF395E.field.doesyourap2852f.label",
              "options": [ { "valueId": "YES" }, { "valueId": "NO" } ], "valueDeterminesMetadata": true },
            "validation": { "required": true\#(editable ? #", "editable": true"# : "") } } } }
        """#
    }

    private func savedRow(status: String, formId: String) -> String {
        #"""
        { "data": [ { "id": "req-1", "formName": "SECURITYASF395E", "entityId": "1234567890", "entityType": "APP",
                      "status": "\#(status)", "isRequired": true, "countries": [ "CHN" ], "formId": "\#(formId)",
                      "lastUpdatedDate": "2026-11-19T00:00:00.000Z" } ] }
        """#
    }

    /// Apple, as the App Compliance page meets it: the metadata for any draft, the save, and the list after it.
    private func apple(editable: Bool = true, saveStatus: Int = 200, formId: String = "form-1") -> MockIrisAPI {
        let api = MockIrisAPI()
        given(api).compliancePost(path: .value(metadata), body: .any, cookies: .value("myacinfo=a"))
            .willReturn(reply(200, question(editable: editable)))
        let saved = #"{ "data": { "id": "\#(formId)", "requirementId": "req-1", "formName": "SECURITYASF395E", "fields": [ { "id": "field-1", "sValue": "NO" } ], "status": "COLLECTED_VERIFY_NOT_NECESSARY" } }"#
        if saveStatus == 200 {
            given(api).compliancePost(path: .value(forms), body: .any, cookies: .value("myacinfo=a")).willReturn(reply(200, saved))
            given(api).compliancePut(path: .value("\(forms)/form-1"), body: .any, cookies: .value("myacinfo=a")).willReturn(reply(200, saved))
        } else {
            // IrisAPI answers a refusal by throwing, as IrisClient does.
            let refusal = IrisAPIError.httpError(statusCode: saveStatus, body: "Forbidden")
            given(api).compliancePost(path: .value(forms), body: .any, cookies: .value("myacinfo=a")).willThrow(refusal)
            given(api).compliancePut(path: .value("\(forms)/form-1"), body: .any, cookies: .value("myacinfo=a")).willThrow(refusal)
        }
        given(api).complianceGet(path: .value("accounts/team-uuid/requirements"), queryItems: .any, cookies: .any)
            .willReturn(reply(200, savedRow(status: "COLLECTED_VERIFY_NOT_NECESSARY", formId: formId)))
        given(api).complianceGet(path: .value(forms), queryItems: .any, cookies: .any)
            .willReturn(reply(200, "{ \"data\": [ \(saved.dropFirst(10).dropLast(2)) ] }"))
        return api
    }

    private func requirement(declaration: ComplianceDeclaration? = nil, status: ComplianceStatus = .missingInfo) -> ComplianceRequirement {
        ComplianceRequirement(id: "req-1", appId: "1234567890", kind: .securityAssessment, regions: ["CHN"], isRequired: true,
                              status: status, updatedAt: nil, requiredActions: [], declaration: declaration)
    }

    private let answeredNo = ComplianceRequirement(
        id: "req-1", appId: "1234567890", kind: .securityAssessment, regions: ["CHN"], isRequired: true,
        status: .active, updatedAt: "2026-11-19T00:00:00.000Z", requiredActions: [],
        declaration: ComplianceDeclaration(id: "form-1", answer: .no)
    )

    @Test func `should answer No for the first time and show the requirement active`() async throws {
        let api = apple()

        let row = try await IrisSDKComplianceRepository(api: api, accounts: accounts())
            .declare(session: session, requirement: requirement(), answer: .notOffered)

        #expect(row == answeredNo)
        verify(api).compliancePost(
            path: .value(forms),
            body: .value(Data(#"{"accountId":"team-uuid","entityId":"1234567890","fields":[{"id":"field-1","sValue":"NO"}],"requirementId":"req-1"}"#.utf8)),
            cookies: .any
        ).called(1)
    }

    @Test func `should ask Apple for the form, first empty and then with No picked, before saving`() async throws {
        let api = apple()

        _ = try await IrisSDKComplianceRepository(api: api, accounts: accounts())
            .declare(session: session, requirement: requirement(), answer: .notOffered)

        verify(api).compliancePost(
            path: .value(metadata),
            body: .value(Data(#"{"accountId":"team-uuid","entityId":"1234567890","form":{"fields":[]},"requirementId":"req-1"}"#.utf8)),
            cookies: .any
        ).called(1)
        verify(api).compliancePost(
            path: .value(metadata),
            body: .value(Data(#"{"accountId":"team-uuid","entityId":"1234567890","form":{"fields":[{"id":"field-1","sValue":"NO"}]},"requirementId":"req-1"}"#.utf8)),
            cookies: .any
        ).called(1)
    }

    @Test func `should change an answered requirement in place, keeping its declaration`() async throws {
        let api = apple()

        let row = try await IrisSDKComplianceRepository(api: api, accounts: accounts())
            .declare(session: session, requirement: requirement(declaration: ComplianceDeclaration(id: "form-1", answer: .no), status: .active),
                     answer: .notOffered)

        #expect(row == answeredNo)
        verify(api).compliancePut(
            path: .value("\(forms)/form-1"),
            body: .value(Data(#"{"accountId":"team-uuid","entityId":"1234567890","fields":[{"id":"field-1","sValue":"NO"}],"formId":"form-1","requirementId":"req-1"}"#.utf8)),
            cookies: .any
        ).called(1)
        verify(api).compliancePost(path: .value(forms), body: .any, cookies: .any).called(0)
    }

    @Test func `should refuse without saving when Apple serves the form read-only`() async {
        let api = apple(editable: false)

        await #expect(throws: ComplianceError.readOnly(kind: .securityAssessment)) {
            try await IrisSDKComplianceRepository(api: api, accounts: accounts())
                .declare(session: session, requirement: requirement(), answer: .notOffered)
        }
        verify(api).compliancePost(path: .value(forms), body: .any, cookies: .any).called(0)
    }

    @Test func `should say the role can't edit App Compliance when Apple forbids the save`() async {
        let api = apple(saveStatus: 403)

        await #expect(throws: ComplianceError.roleCannotEdit(appId: "1234567890")) {
            try await IrisSDKComplianceRepository(api: api, accounts: accounts())
                .declare(session: session, requirement: requirement(), answer: .notOffered)
        }
    }

    @Test func `should explain a read-only form and a forbidden save`() {
        #expect(ComplianceError.readOnly(kind: .securityAssessment).description
            == "Apple won't take a change to Security Assessment right now: the App Compliance page shows it read-only.")
        #expect(ComplianceError.roleCannotEdit(appId: "1234567890").description
            == "Your App Store Connect role can't edit App Compliance for app 1234567890. Ask your Account Holder or an Admin.")
    }
}
