# App Compliance — "Does your app offer AIGC services in China mainland?"

**Status: BUILT** (slices 1–5 and 7: list, declare No, declare Yes with evidence, CLI and REST). Slice 6, the check-readiness warning, waits on the list shipping. User guide: [README.md](README.md). Apple has no public API for App Compliance: it is absent from appstoreconnect-swift-sdk 4.6.1 and from Apple's own OpenAPI spec 4.6 (checked 2026-11-17). The web UI reads it from a private service outside `/iris/v1`, `ppm/compliancerequirements/v1`, which uses the same Apple ID session cookies. Every read and write the page makes is captured (below).

This document owns **the declarations an app keeps current so it can stay on the store in a regulated region**. Its neighbours own the rest:

| For | Read |
|---|---|
| Getting an Apple ID session (cookies, `teamId`) | [Iris](../iris/README.md), [Iris SRP login](../iris/iris-srp-login.md) |
| Build export compliance (`usesNonExemptEncryption`) | [`asc builds`](../../commands.md#asc-builds), a different public-API resource |
| Age rating declaration | [Age rating](../age-rating/README.md), a different public-API resource |
| Whether a version is ready to submit | [Check readiness](../version-check-readiness/README.md). It does not read compliance yet; see Open question 6 |

---

## What the product already says

```
  "App Compliance"                          ← the page; one per app
  "Regulations and permits relevant to your app in the App Store"
  COMPLIANCE NAME  "Security Assessment"    ← a requirement has a human name
                   "AI Generated or Synthetic Content"
  COUNTRIES OR REGIONS  "China mainland"    ← a requirement applies to a region
  LAST UPDATED  "Nov 17, 2026" / "-"        ← "-" = never answered
  STATUS  "Active" / "Missing Info"         ← help page adds "Pending Verification", "Verification Failed"
  "Add Info" / "Edit" / "View"              ← the next action depends on status: Missing Info → Add Info,
                                               Active → Edit, Pending Verification (with a ? tooltip) → View
  "Does your app offer AIGC services in China mainland?"  Yes / No
  Security Assessment modal: "Chinese law requires apps with features like end-to-end encrypted
    instant messaging or distribution of AI-generated content (AIGC) offered in China mainland to
    complete a Security Assessment with the National Internet Security Management Service Platform."
    "Does your app include features that require a security assessment in China mainland?"  Yes / No · Save
    Yes → "Proof of a Completed Security Assessment" (?)  [Choose File (Required)]
          "Security Assessment Report" (?)                [Choose File (Required)]
          a chosen file shows its name and "Delete"; Save enables once both are chosen
  AI Generated or Synthetic Content modal: "AI-generated or synthetic content (AIGC) services, such as
    AI chatbots, AI image or video generation or processing, AI voice or face alteration or generation,
    are subject to the regulatory requirements by the Cyberspace Administration of China (CAC)."
    "Does your app offer AIGC services in China mainland?"  Yes / No · Save
    Yes → "Which filing information would you like to provide?" (?)  Large Language Model (LLM) / Algorithm (Algo)
            Algo → "Algorithm Name" (?) [text]   "Algorithm Filing Number" (?) [text]
          "Are your app's AI features powered by third-party technology?"  Yes / No
            Yes → "Authorization or usage agreement from third-party technology"  [Choose File (Required)]
  Help: "complete the AI-generated/synthetic content and Security Assessment declarations"
  Help: Yes → filing number + filing name (AIGC); proof screenshot + assessment report (Security Assessment)
```

The version page carries one banner per unanswered requirement, each linking to the page:

```
  "Security Assessment Required for China Mainland Distribution"
    "provide proof of a completed Security Assessment and a report.
     Existing apps must comply by Jan 31, 2027; new apps should submit immediately."
  "AIGC Services Declaration Required for China Mainland Distribution"
    "submit an AI-generated or synthetic content (AIGC) services declaration and filing information. …"
  "Go to App Compliance"
```

So the domain is a **checklist of requirements**, and each requirement takes a **yes/no declaration**. Answering Yes also requires evidence, and the kind of evidence depends on the requirement. Answering No requires none.

The same page also holds the Digital Services Act trader status, the ICP filing number, the Vietnam game license and the regulated medical device declaration. They are **out of scope** for this lap. They are separate cards with their own shapes and haven't been captured here.

## The one sentence

**An app's compliance is the list of regional requirements that apply to it, each answered by a declaration whose status says whether the app may stay on sale in that region.**

```
 App 1234567890
  ├─ Security Assessment       China mainland   declaration: No   → Active
  └─ AI Generated or Synthetic China mainland   (none)            → Missing Info  → declare
```

## The captured wire format

All IDs and dates below are placeholders. Every call is on the same service, scoped by the same account.

### The requirements — what applies (every row on the page)

```
GET https://appstoreconnect.apple.com/ppm/compliancerequirements/v1/accounts/{accountId}/requirements?entity_id={appId}
```

```json
{ "data": [
  { "id": "req-1", "formName": "SECURITYASF395E", "entityId": "1234567890", "entityType": "APP",
    "status": "PENDING_COLLECT", "isRequired": true, "countries": [ "CHN" ] },
  { "id": "req-2", "formName": "AIGENERATEFD1DE", "entityId": "1234567890", "entityType": "APP",
    "status": "PENDING_COLLECT", "isRequired": true, "countries": [ "CHN" ] }
] }
```

- Unanswered requirements **do** come back here, with `status: PENDING_COLLECT`. This is the Missing Info source.
- The app is a query parameter, spelled `entity_id` (snake case), not a path segment.
- `countries` holds ISO 3166-1 alpha-3 codes. `CHN` is what the page shows as "China mainland".
- `formName` is the only kind key. There is no human name and no other stable token, so the page's "Security Assessment" is a client-side label.
- An unanswered requirement has no date and no form.

**After a Yes was saved**, the same call returns the answered requirement with more fields:

```json
{ "id": "req-1", "formName": "SECURITYASF395E", "entityId": "1234567890", "entityType": "APP",
  "status": "COLLECTED_VERIFY_PENDING", "isRequired": true, "countries": [ "CHN" ],
  "formId": "form-1",
  "dateSigned": "2026-01-01T00:00:00.000Z", "lastUpdatedDate": "2026-01-01T00:00:00.000Z",
  "requiredActions": [ "APP_BINARY_SUBMISSION" ] }
```

- `formId` names the declaration, so the requirement already says which form answers it.
- `lastUpdatedDate` (ISO 8601, unlike the declarations' epoch milliseconds) is the page's LAST UPDATED. `dateSigned` is when it was first answered; it matched `lastUpdatedDate` here only because the row hadn't been changed since.
- A Yes with evidence goes to `COLLECTED_VERIFY_PENDING`: Apple has the files and has not verified them. The captured No went to `COLLECTED_VERIFY_NOT_NECESSARY` (on the declaration).
- `requiredActions: ["APP_BINARY_SUBMISSION"]` appeared with the pending Yes. The likely reading is that verification happens with the app's next submission for review (Open question 10).
- So the list, status and date of every row come from this one call. The declarations call is needed only for the answer itself (`sValue`).

### The declarations — what was answered

```
GET https://appstoreconnect.apple.com/ppm/compliancerequirements/v1/accounts/{accountId}/entities/{appId}/forms
```

```json
{ "data": [ {
    "id": "form-1",
    "requirementId": "req-1",
    "formName": "SECURITYASF395E",
    "fields": [ { "id": "field-1", "sValue": "NO", "verificationStatus": "FIELD_VERIFY_NOT_NECESSARY" } ],
    "status": "COLLECTED_VERIFY_NOT_NECESSARY",
    "createdAt": "1794879753633", "updatedAt": "1794879753633",
    "createdBy": "user-1", "updatedBy": "user-1"
} ] }
```

- **Only answered requirements come back.** A declaration joins its requirement on `requirementId` = requirement `id`.
- **With none, it answers `{}`** (captured live on two new apps), not `{"data": []}`: the service leaves out what is empty, here and in every other response (no `formId`, dates or `requiredActions` until they apply).
- **The page doesn't call it to draw the table** (captured in the browser): only when a row's Add Info / Edit / View dialog opens.
- Timestamps are epoch milliseconds, encoded as strings.
- The second captured declaration was `AIGENERATEFD1DE`, with the same shape. The spelling is the same in both calls.

### The form metadata — what a declaration asks

```
POST https://appstoreconnect.apple.com/ppm/compliancerequirements/v1/accounts/{accountId}/entities/{appId}/requirements/{requirementId}/metadata
```

```json
{ "accountId": "{accountId}", "entityId": "{appId}", "requirementId": "{requirementId}",
  "form": { "fields": [] } }
```

Opening the modal sends the empty draft above. The response, for Security Assessment:

```json
{
  "formName": "SECURITYASF395E",
  "formMode": "MODAL",
  "formLabel": "PPM.compliance.form.SECURITYASF395E.title",
  "description": "PPM.compliance.form.SECURITYASF395E.description",
  "form": {},
  "constraints": {
    "field-1": {
      "presentation": {
        "id": "field-1",
        "inputType": "RADIO",
        "label": "PPM.compliance.form.SECURITYASF395E.field.doesyourap2852f.label",
        "options": [
          { "valueId": "YES", "locKey": "PPM.compliance.form.SECURITYASF395E.field.doesyourap2852f.option.YES" },
          { "valueId": "NO",  "locKey": "PPM.compliance.form.SECURITYASF395E.field.doesyourap2852f.option.NO" }
        ],
        "valueDeterminesMetadata": true
      },
      "validation": { "required": true, "editable": true }
    }
  }
}
```

- It is a `POST` because it computes the form for a draft: the body repeats the URL's ids and carries the draft in `form.fields`.
- This is the form's schema, read when the developer taps Add Info. An unanswered requirement has one field: the Yes/No question, a `RADIO` whose `valueId`s (`YES` / `NO`) are the `sValue`s a declaration stores.
- `constraints` is keyed by field id. The declaration's `fields[].id` is assumed to be this same id (Open question 2), so the id is read from here, never hard-coded.
- Every visible word is a localization key (`formLabel`, `description`, `label`, `locKey`), not text. The web client resolves them; the page renders the label as "Does your app include features that require a security assessment in China mainland?". A CLI has to supply its own words per kind.
- `valueDeterminesMetadata: true` means the answer changes the form: picking an option fetches the metadata again with that value (below). A No needs nothing more.
- `form` is the draft the metadata was computed for: `{}` before anything is picked.
- The field key inside the loc key (`doesyourap2852f`) is a label slug plus a hash, like `formName`.
- **AI Generated or Synthetic Content opens the same way**: one required `RADIO` with `YES` / `NO` and `valueDeterminesMetadata: true`, its own constraint id, and loc keys under `PPM.compliance.form.AIGENERATEFD1DE` (field `doesyourap268df2`). The page renders its label as "Does your app offer AIGC services in China mainland?". Its Yes branch is deeper (below).

### The form metadata with Yes picked — the evidence a Yes asks for

Picking Yes posts to the same `…/requirements/{requirementId}/metadata` URL again, presumably with `"form": { "fields": [ { "id": "field-1", "sValue": "YES" } ] }` in the body (the request for this step wasn't copied, but the opening request's shape and the echo below agree). The response echoes the draft in `form` and adds the Yes branch's fields (the Yes/No constraint is unchanged and omitted here):

```json
{
  "formName": "SECURITYASF395E",
  "form": { "fields": [ { "id": "field-1", "sValue": "YES" } ] },
  "constraints": {
    "field-1": { "…": "the Yes/No RADIO, as above" },
    "field-2": {
      "presentation": {
        "id": "field-2", "inputType": "FILE",
        "label":   "PPM.compliance.form.SECURITYASF395E.field.proofofacocb097.label",
        "tooltip": "PPM.compliance.form.SECURITYASF395E.field.proofofacocb097.tooltip"
      },
      "validation": { "required": true, "editable": true,
                      "allowedFileTypes": [ ".doc", ".docx", ".jpeg", ".jpg", ".pdf", ".png" ] }
    },
    "field-3": {
      "presentation": {
        "id": "field-3", "inputType": "FILE",
        "label":   "PPM.compliance.form.SECURITYASF395E.field.securityascf4ff1.label",
        "tooltip": "PPM.compliance.form.SECURITYASF395E.field.securityascf4ff1.tooltip"
      },
      "validation": { "required": true, "editable": true,
                      "allowedFileTypes": [ ".doc", ".docx", ".jpeg", ".jpg", ".pdf", ".png" ] }
    }
  }
}
```

- **The draft's `fields[].id` is the constraint id.** This confirms the shape a save is expected to send: `fields: [{ "id": <constraint id>, "sValue": … }]`.
- Security Assessment's Yes asks for two required files: **Proof of a Completed Security Assessment** (`proofofaco…`) and the **Security Assessment Report** (`securityasc…`), each `.doc`, `.docx`, `.jpeg`, `.jpg`, `.pdf` or `.png`. The file size limit is not in the metadata.
- What a `FILE` field's `sValue` holds once uploaded (an upload id, a file name) is not captured.

### The AIGC form with Yes picked — a tree of questions

AIGC's Yes branch is not a flat list of evidence. Each answer can bring more fields, and each `RADIO` that does is marked `valueDeterminesMetadata: true`. The draft is posted again after every such pick. The captured request, after picking Yes:

```json
{ "accountId": "{accountId}", "entityId": "{appId}", "requirementId": "req-2",
  "form": { "fields": [ { "id": "aigc-offers", "sValue": "YES" } ] } }
```

The full tree, from that response and the next one (after Algorithm and third-party Yes were picked). Field ids are placeholders; the slug in brackets is the field key inside each loc key:

```
aigc-offers        RADIO  YES | NO                    [doesyourap268df2]  "Does your app offer AIGC services in China mainland?"
└─ YES
   ├─ filing-type  RADIO  LARGE | ALGOR  (tooltip)    [whichfilinc6deb2]  "Which filing information would you like to provide?"
   │  ├─ ALGOR
   │  │  ├─ algorithm-name    TEXT (tooltip)          [algorithmname2]    "Algorithm Name"
   │  │  └─ algorithm-filing  TEXT (tooltip)          [algorithmf737252]  "Algorithm Filing Number"
   │  └─ LARGE
   │     ├─ llm-name          TEXT (tooltip)          [llmname2]          "LLM Name"
   │     └─ llm-filing        TEXT (tooltip)          [llmfilingnumber4]  "LLM Filing Number"
   └─ third-party  RADIO  YES | NO                    [areyourappd75c12]  "Are your app's AI features powered by third-party technology?"
      ├─ YES
      │  └─ authorization     FILE  .doc .docx .jpeg .jpg .pdf .png   [authorizat9286a3]
      │                             "Authorization or usage agreement from third-party technology"
      └─ NO                   (not captured; presumably nothing more)
```

Every field is `required: true, editable: true`. The response's `form` after the second pick:

```json
{ "fields": [
  { "id": "aigc-offers",      "sValue": "YES" },
  { "id": "filing-type",      "sValue": "ALGOR" },
  { "id": "algorithm-name",   "sValue": "" },
  { "id": "algorithm-filing", "sValue": "" },
  { "id": "third-party",      "sValue": "YES" }
] }
```

- A `TEXT` field the branch opens is echoed with `sValue: ""`, and the web client sends a `RADIO` nobody has picked yet as `sValue: ""` too. A `FILE` field is **not** in the draft until a file is attached.
- The tooltips and the field order on the page come from the metadata; the page's order is the constraints' order.
- So what an AIGC Yes must carry is: the filing type and its name and filing number, and whether third-party technology is used, with the authorization file if it is. The help page's "optional third-party authorization" is optional only in the sense that answering No skips it.

The web client also reads `GET …/accounts/{accountId}/entities/{appId}/forms` (the declarations) while the modal is open, with the same headers as the metadata `POST`.

### Saving a declaration — first answer

```
POST https://appstoreconnect.apple.com/ppm/compliancerequirements/v1/accounts/{accountId}/entities/{appId}/forms
```

```json
{ "accountId": "{accountId}", "entityId": "{appId}", "requirementId": "req-2",
  "fields": [ { "id": "aigc-offers", "sValue": "NO" } ] }
```

```json
{ "data": {
    "id": "form-2",
    "requirementId": "req-2",
    "formName": "AIGENERATEFD1DE",
    "fields": [ { "id": "aigc-offers", "sValue": "NO", "verificationStatus": "FIELD_VERIFY_NOT_NECESSARY" } ],
    "status": "COLLECTED_VERIFY_NOT_NECESSARY",
    "createdAt": "1790000000000", "updatedAt": "1790000000000",
    "createdBy": "user-1", "updatedBy": "user-1"
} }
```

- **Saving posts the draft to the declarations collection**, the URL the declarations are read from. The body is the metadata draft's fields, but at the top level (`fields`), not under `form`.
- **The response is the new declaration**, the same shape as one item of the declarations `GET`, with its new form id. A No is not verified (`FIELD_VERIFY_NOT_NECESSARY`).
- Picking No had already posted the draft to `…/metadata`, which answered with no further fields: a No ends the tree. A tool can use that answer the same way, and save once the metadata asks for nothing it hasn't filled.
- `createdBy` / `updatedBy` are the signed-in person's numeric Apple user id.
- Afterwards the requirement reads `status: COLLECTED_VERIFY_NOT_NECESSARY`, with `formId`, `dateSigned` and `lastUpdatedDate`, and **no** `requiredActions`. A No needs nothing further from Apple.

### Saving a declaration — a change

```
PUT https://appstoreconnect.apple.com/ppm/compliancerequirements/v1/accounts/{accountId}/entities/{appId}/forms/{formId}
```

```json
{ "accountId": "{accountId}", "entityId": "{appId}", "requirementId": "req-1", "formId": "form-1",
  "fields": [ { "id": "field-1", "sValue": "NO" } ] }
```

- **A change updates the same declaration**: the form id in the URL and as `formId` in the body; otherwise the first-answer body. The response is the declaration with the **same id**, the same `createdAt` and a new `updatedAt`.
- Afterwards the requirement keeps its `formId` and its `dateSigned` (when it was first answered) and gets a new `lastUpdatedDate` (the page's LAST UPDATED).
- Only an Active declaration can be changed; a pending one is read-only. Captured as an Active No saved again as No.

### A stored Yes with files

The declarations `GET`, after the Security Assessment Yes was saved:

```json
{ "id": "form-1", "requirementId": "req-1", "formName": "SECURITYASF395E",
  "fields": [
    { "id": "field-1", "sValue": "YES", "verificationStatus": "FIELD_VERIFY_NOT_NECESSARY" },
    { "id": "field-2", "verificationStatus": "FIELD_VERIFY_PENDING",
      "fileContent": { "fileId": "file-1", "fileName": "proof.png", "fileType": "image/png", "fileSizeBytes": "34188" } },
    { "id": "field-3", "verificationStatus": "FIELD_VERIFY_PENDING",
      "fileContent": { "fileId": "file-2", "fileName": "report.pdf", "fileType": "application/pdf", "fileSizeBytes": "120000" } }
  ],
  "status": "COLLECTED_VERIFY_PENDING",
  "createdAt": "1790000000000", "updatedAt": "1790000000000", "createdBy": "user-1", "updatedBy": "user-1" }
```

- **A `FILE` field holds `fileContent`, not `sValue`**: Apple's `fileId` plus the name, MIME type and size (a string) of the file as uploaded.
- **Verification is per field.** The Yes itself is `FIELD_VERIFY_NOT_NECESSARY`; each file is `FIELD_VERIFY_PENDING`. The declaration's status follows its files.
- Apple issues the `fileId` when it stores the file; the client never sends one (below).

### Files travel inside the draft

There is no upload request. Choosing a file puts its bytes into the draft, base64-encoded, and every later `…/metadata` post carries them:

```json
{ "accountId": "{accountId}", "entityId": "{appId}", "requirementId": "req-1",
  "form": { "fields": [
    { "id": "field-1", "sValue": "NO" },
    { "id": "field-2", "fileContent": { "fileData": "iVBORw0KGgo…", "fileName": "proof.png", "fileType": "image/png" } },
    { "id": "field-3", "fileContent": { "fileData": "iVBORw0KGgo…", "fileName": "report.png", "fileType": "image/png" } }
  ] } }
```

- **A draft file is `fileContent: { fileData, fileName, fileType }`**: the whole file as base64, its name and its MIME type. A stored one is `{ fileId, fileName, fileType, fileSizeBytes }`. Apple turns the first into the second when it saves.
- This capture had Yes, two files chosen, then No picked. The metadata answered with only the Yes/No field and dropped the two files from `form`: **fields the current answers don't ask for are dropped**. A tool should drop them itself before saving rather than rely on that.
- **A Yes with files is saved the same way** (captured on AIGC): the first-answer `POST …/forms` with every field, a file as `{ id, fileContent: { fileData, fileName, fileType } }`. The response carries the stored form, the file now `{ fileId, fileName, fileType, fileSizeBytes }`.
- No size limit is in the metadata. A base64 body grows by a third; a large assessment report makes a large `POST`.

### Opening an answered requirement

Edit posts the **stored declaration** as the draft:

```json
{ "accountId": "{accountId}", "entityId": "{appId}", "requirementId": "req-1",
  "form": { "id": "form-1", "requirementId": "req-1", "formName": "SECURITYASF395E",
            "fields": [ …the stored fields, fileContent included… ], "status": "COLLECTED_VERIFY_PENDING", … } }
```

The response echoes the stored fields in `form`, and the constraints come back **without `editable: true`** (`validation` is only `{ "required": true, … }`). While a declaration is pending verification, Apple serves it read-only: seen on both Security Assessment and AIGC, and the page shows every field greyed out with Save disabled. An Active declaration **is** editable: its row offers Edit, the modal opens on the stored answer with live controls, and Save enables once something changes. Picking a different answer in Edit posts a draft that keeps `requirementId` but **drops the form `id`** (`form: { requirementId, fields }`), and the response is the new branch's form (No → Yes brought back both file fields, editable). Saving the change is nonetheless a `PUT` on the existing form (below): the dropped `id` comes back as `formId` in the save body.

### The same requirement on a second app

Picking Yes on Security Assessment for a second app of the same account sent the same request with the other app's `entityId`, and:

- **The requirement id was the same** as on the first app. A requirement id names the regulation for the account, not one app's row; the row is the requirement id plus `entityId`.
- **Every constraint id was the same** (the Yes/No and both `FILE` fields), with the same loc keys and the same `allowedFileTypes`.

Not yet seen: an app on another account, so whether these ids are global or per account is open.

### Saving an AIGC Yes

```json
{ "accountId": "{accountId}", "entityId": "{appId}", "requirementId": "req-2",
  "fields": [
    { "id": "aigc-offers",   "sValue": "YES" },
    { "id": "filing-type",   "sValue": "LARGE" },
    { "id": "llm-name",      "sValue": "Example Model" },
    { "id": "llm-filing",    "sValue": "Example-0000" },
    { "id": "third-party",   "sValue": "YES" },
    { "id": "authorization", "fileContent": { "fileData": "JVBERi0…", "fileName": "agreement.pdf", "fileType": "application/pdf" } }
  ] }
```

The answer, in the response and afterwards on the requirement:

| Field | `verificationStatus` |
|---|---|
| the Yes/No answers and the filing type | `FIELD_VERIFY_NOT_NECESSARY` |
| LLM name, LLM filing number | `FIELD_VERIFY_PENDING` |
| the authorization file | `FIELD_VERIFY_PENDING` |

The declaration is `COLLECTED_VERIFY_PENDING`, and the requirement gains `requiredActions: ["APP_BINARY_SUBMISSION"]`, as the Security Assessment Yes did. **Apple verifies what a person typed as well as what they attached**: a filing name and number are checked, not just stored.

### Request headers

```
Referer: https://appstoreconnect.apple.com/apps/{appId}/distribution/compliance
Content-Type: application/json
x-csrf-itc: [asc-ui]                      ← on the requirements GET
Accept: application/vnd.api+json, application/json, text/csv   ← requirements GET
Accept: application/json                                       ← metadata POST
```

Neither the copied metadata `POST` nor the save `POST` carried `x-csrf-itc`, so this service doesn't ask for it (unlike its sibling `complianceform/v1`, which rejects writes without it). Sending it anyway does no harm; the requirements `GET` does.

### All calls

- `accountId` is the team's **`publicProviderId`** from `olympus/v1/session`. It already arrives as `IrisAuthSession.teamId`, and the captured URLs matched a saved session's `teamId`. It is **not** the numeric `providerID`.
- `{appId}` is the numeric App Store app ID.
- A sibling service, `ppm/complianceform/v1`, serves the regulated medical device declaration with a different shape (`requirementData[].requirements[]`, `contentId`). It is not this one; see Open question 2 for what it suggests about saving.

---

## 1 · Ubiquitous language

| Term | Meaning | Not to be confused with |
|---|---|---|
| **App Compliance** | The page: every compliance requirement for one app | Export compliance on a build |
| **Compliance requirement** | One regulation that applies to the app in a region ("Security Assessment, China mainland"). Apple's API calls it a *requirement* | The help-page article about it |
| **Kind** | Which regulation the requirement is. This lap covers Security Assessment and AI Generated or Synthetic Content | Apple's `formName` code, which is only how the wire spells it |
| **Region** | Where the requirement applies, as Apple's `countries` code (`CHN`). Shown by its name ("China mainland") | A storefront |
| **Declaration** | The developer's answer to one requirement. Apple's API calls it a *form* | `AgeRatingDeclaration`, `AppEncryptionDeclaration`, `AccessibilityDeclaration`: public-API resources with no relation to this one |
| **Question** | The one Yes/No field a declaration answers. Apple's metadata calls it a *constraint*; its id is what a save names | The localized label text |
| **Answer** | Yes (the app offers the regulated feature in the region) or No (it doesn't, or the feature is disabled or geoblocked there) | |
| **Evidence** | What a Yes must carry: filing number and filing name (AIGC), or the proof of a completed assessment and the assessment report, as files (Security Assessment) | |
| **Status** | Missing Info · Pending Verification · Verification Failed · Active | The raw wire values (`PENDING_COLLECT`, `COLLECTED_VERIFY_PENDING`, `COLLECTED_VERIFY_NOT_NECESSARY`) |
| **Required action** | What Apple still needs before it verifies a declaration (`APP_BINARY_SUBMISSION`) | Something the developer must fill in on the form |
| **Account** | The team, identified by `publicProviderId` (a UUID) | `providerID`, the numeric ID |

**"Declaration", not "form".** *Form* is Apple's backstage word. Apple's help page and the people filling it in say *declaration*. The `formName` code stays in the infrastructure mapper.

## 2 · The aggregate — from the root down

```
ComplianceRequirement                  one row on the App Compliance page (aggregate root)
 ├─ id         : String                Apple's requirement id; stable before and after answering, and the SAME for every app
 │                                     (it names the regulation, not the row): a row is identified by (id, appId)
 ├─ appId      : String                parent; injected by the adapter (also `entityId` on the wire)
 ├─ kind       : ComplianceKind        which regulation, from `formName`; decides what a Yes must carry
 ├─ regions    : [String]              `countries`, e.g. ["CHN"]
 ├─ isRequired : Bool
 ├─ updatedAt  : Date?                 `lastUpdatedDate`; nil = never answered, shown "-"
 ├─ requiredActions : [RequiredAction] e.g. .appBinarySubmission; unknown values kept raw
 ├─ declarationId : String?            the requirement's `formId`: the declaration a change updates; nil ⇒ never answered
 └─ status     : ComplianceStatus      mapped from the requirement's `status`

ComplianceAnswer                       what `declare` sends (not part of the row)
 └─ .notOffered | .offered(Evidence)   EVIDENCE ONLY ON YES
```

**The row is what the page draws, from the page's own call.** The requirements response alone carries everything the table shows (name, regions, last updated, status) and the `formId` a change needs, so `list` makes that one call, as the page does. The declarations themselves (the stored answer, its files) aren't read for the list: the page doesn't show them in the table either, and reading them doubled the requests and was the call that answered `{}`. They belong to a future `get` of one requirement, which is what the page's dialog does.

There is no `AppCompliance` wrapper type. It would just be the plural of `ComplianceRequirement`, with no rule of its own yet. It earns a type if Open question 6 ("may this app ship in region X?") gets answered, because that rule belongs to the collection.

## 3 · The kinds and the rich types

| Kind | Wire `formName` | A Yes must carry | Its own rules |
|---|---|---|---|
| **securityAssessment** | `SECURITYASF395E` | two files, each `.doc`/`.docx`/`.jpeg`/`.jpg`/`.pdf`/`.png`: proof of a completed assessment, and the assessment report | Required when the app distributes AIGC or offers encrypted instant messaging |
| **aiGeneratedContent** | `AIGENERATEFD1DE` | the filing type (LLM or Algorithm) with its name and filing number (text), and whether third-party technology powers it, with the authorization or usage agreement (a file) when it does | Offered for AI chatbots, AI image or video generation or processing, AI voice or face alteration or generation (the modal's examples) |
| **unrecognized(formName)** | anything else | unknown | Listed as-is, never offered `declare` |

### `ComplianceAnswer` — the developer's Yes or No

> **Pointable as:** the radio button the developer ticked in the Yes/No dialog.

| | |
|---|---|
| **Owns — a Yes carries its kind's evidence; a No carries nothing** | `.notOffered` has no payload. `.offered(SecurityAssessmentEvidence)` and `.offered(AIGCFilingEvidence)` are different shapes, so a Yes without a filing number can't be built |
| **The evidence shapes** | `SecurityAssessmentEvidence(proof: File, report: File)`, where a `File` is a local document (name, MIME type, bytes) going in, and Apple's `fileId`, name, type and size coming back. `AIGCFilingEvidence(filing: AIGCFiling, thirdParty: ThirdPartyTechnology)`, where `AIGCFiling` is `.algorithm(name, filingNumber)` or `.largeLanguageModel(name, filingNumber)` and `ThirdPartyTechnology` is `.none` or `.used(authorization: File)`. Each branch of Apple's tree is one case, so a combination the form can't hold can't be built |
| **It answers** | `wireValue` → `"YES"` / `"NO"` |
| **Never** | A `filingNumber` field that "is ignored when the answer is No" |

### `ComplianceStatus` — what the STATUS column says

> **Pointable as:** the icon and label in the STATUS column.

| | |
|---|---|
| **Owns — an unknown wire status still lists** | `.missingInfo · .pendingVerification · .verificationFailed · .active · .unrecognized(raw)` |
| **It answers** | `isActive` (the app may stay on sale in the region) · `needsAction` (Missing Info or Verification Failed) · `isPendingVerification` |
| **Never** | Guess a mapping. Observed so far, on the requirement and the declaration alike: `PENDING_COLLECT → missingInfo`, `COLLECTED_VERIFY_PENDING → pendingVerification`, `COLLECTED_VERIFY_NOT_NECESSARY → active` (a No). Every other wire value is `.unrecognized` until captured (Open question 3) |

## 4 · The tells

```
asc iris app-compliance list --app-id 1234567890
    → [ComplianceRequirement]: each row knows its own status and next command

asc iris app-compliance declare --app-id 1234567890 --requirement-id req-1 --answer no
    → requirement.declare(.notOffered, repo:)    the requirement checks it may be declared
                                                 (recognized kind, not pending)

requirement.structuredAffordances
    → "declare" only when kind is recognized and !status.isPendingVerification
```

The adapter resolves the account itself: it uses `IrisAuthSession.teamId` when the session came from `asc iris auth login`, and otherwise calls `olympus/v1/session` (browser cookies and `ASC_IRIS_COOKIES` don't carry a team ID). The command never asks for `--account-id`, because a user can't see that value anywhere.

The iris repositories reach Apple through the `@Mockable IrisAPI` role, played by `IrisClient` in `Iris/Internal/System/`; the requests themselves are built by `IrisRequest`, which hard-codes the base `…/iris/v1`. `IrisRequest` gains the `…/ppm/compliancerequirements/v1` base with the same cookies and headers, and `IrisAPI` gains the calls the page makes there (a `PUT` for a change, beside the `get`, `post` and `delete` it has). There is no new auth path.

## 5 · Invariants (each law, one owner)

| # | Law | Owner |
|---|---|---|
| 1 | A requirement nobody has answered shows Missing Info | `ComplianceRequirement` (derives `status`) |
| 2 | A requirement always belongs to the app it was listed under, and is addressed by its id **and** that app, never by its id alone (the id is shared across apps) | adapter mapper (injects `appId`) |
| 3 | A Yes always carries its kind's evidence; a No carries none | `ComplianceAnswer` (shape) |
| 4 | An unknown form or status is still listed, never dropped and never a crash | `ComplianceKind` / `ComplianceStatus` (`.unrecognized`) |
| 5 | You're offered `declare` only for a recognized kind that isn't awaiting verification: Missing Info (a first answer), Active (a change) and Verification Failed (a resubmission, assumed) | `ComplianceRequirement.structuredAffordances` |
| 5a | `declare` saves only if the requirement's metadata says its fields are `editable`; otherwise it refuses without writing. Apple's own answer decides, so a wrong guess about a status never writes to a read-only declaration | adapter (`declare` reads metadata first) |
| 6 | The account in the URL is the team's `publicProviderId`, never the numeric `providerID` | adapter (account resolution) |
| 7 | Every requirement is a row whether or not it was answered, and names the declaration that answers it (`formId`) | adapter (the requirements mapper) |
| 8 | A declaration names each field by the id the requirement's metadata gives, read for the chosen answers before every save; an id is never hard-coded or guessed. The adapter finds which constraint is which by the field key in its `label` loc key (`algorithmname2`), and walks the tree one pick at a time | adapter (`declare` reads metadata first) |
| 9 | A file is offered for a `FILE` field only if its extension is in that field's `allowedFileTypes` | `ComplianceAnswer` evidence types, from the metadata |
| 10 | A save sends only the fields the metadata asks for under the chosen answers; a field from an abandoned branch (a file chosen before switching to No) is dropped | adapter (`declare` builds the body from the metadata) |

## 6 · Build sequence (test-first, each slice green)

0. ~~**Capture**~~ Done. Every call the page makes is captured; nothing blocks slices 1–6. Also the AIGC Yes metadata, `metadata` for an answered requirement, and the Verification Failed status. The reads, and their responses after a Yes, are captured.
1. **Public face** (`Sources/ASCKit/Iris/Compliance/`): `ComplianceKind`, `ComplianceStatus`, `ComplianceAnswer` (No only), `ComplianceRequirement` + affordances, `@Mockable IrisComplianceRepository` (CRUD over requirements and declarations, so it keeps the `Repository` name; `requirement.declare(…)` is the workflow, on the model). *Pinned: laws 1, 3 (No), 4, 5.*
2. **Read** (`Sources/ASCKit/Iris/Compliance/Internal/`, through `IrisAPI`): the ppm base on `IrisRequest`; account resolution; `listRequirements(session:appId:)` from the page's one call (captured fixtures, placeholder IDs), tested on `MockIrisAPI`. *Pinned: laws 2, 6, 7; `entity_id` query; unknown `formName` and status survive; a missing list reads as empty.*
3. **`asc iris app-compliance list` + REST** `GET /api/v1/iris/apps/:appId/compliance-requirements`. *Pinned: full JSON snapshot; `_links.declare` only on eligible rows.*
4. **`declare --answer no` + REST** (reads the requirement's metadata for the question's id, then saves; *pinned: law 8*) `POST /api/v1/iris/apps/:appId/compliance-requirements/:requirementId/declare` (the app is in the path because a requirement id alone names no row). A first answer is a `POST …/forms`; a change to an Active one is a `PUT …/forms/{formId}` (the requirement's `formId`). A pending one is never offered `declare`.
5. **Yes with evidence**: per-kind evidence types and file flags; files read from disk and sent base64 in `fileContent.fileData`. *Pinned: laws 9, 10.* The body is captured (AIGC Yes with a file).
6. **Readiness** (after the list ships): `AppCompliance` collection + availability; check-readiness warns for a non-Active requirement only in a region the app is sold in (Open question 6).
7. **Docs**: `README.md` for users, one CHANGELOG line, `make docs`, and a link from the iris README's "Other iris commands".

## 6a · What the build settled

- **`list` makes only the page's own call** (requirements) and the row carries `declarationId` from `formId`. An earlier build also read the declarations and joined them (with orphan declarations as rows); it was dropped once the browser showed the page doesn't, and a new app's `{}` broke it. The evidence types (`ComplianceEvidence`) are only what a Yes *sends*.
- **The account is asked of olympus on every call**, not read from a saved `teamId`, so a browser-cookie or `ASC_IRIS_COOKIES` session works the same as `asc iris auth login`. No `publicProviderId` → `ComplianceError.teamUnknown`.
- **Law 1's owner is `ComplianceStatus(wireValue:)`**: Apple already sends `PENDING_COLLECT` for an unanswered requirement.
- **The answer a form holds is its first field**, the Yes/No it opens with; only a Yes opens more fields.
- **`declare` is one loop for every answer**: post the draft to `…/metadata`, fill each field Apple newly asks for (by the key in its label), repeat until Apple asks for nothing new, then save exactly those fields. Any field Apple won't take a change to stops it (law 5a). A No ends after its first pick.
- **The service leaves out what is empty** (`{}` for no declarations, seen live on two new apps), so every response reads a missing list as empty. **Fixtures are captures**, never a shape guessed at: the guessed `{"data": []}` is how the `{}` slipped past the tests.
- **Verified live** (2026-11-19, on test apps that won't be submitted, with files and filing values marked as tests): list on new apps (both Missing Info, as the page shows); a first No on each form (`POST`, → Active); a change to an Active one (`PUT`, same declaration id, new LAST UPDATED); a Security Assessment Yes with two PDFs (stored as files, sizes byte-exact, → Pending Verification with `APP_BINARY_SUBMISSION`); all four AIGC Yes combinations, LLM / Algorithm × third-party Yes / No, each storing only its branch's fields (one as a `PUT` changing an Active No to Yes); and the refusals that write nothing: a Pending Verification row, a Yes missing its report, a `.txt` file against Apple's own `allowedFileTypes`.
- **Third-party No asks for nothing more** (verified live; it was the one branch not captured).
- **Field ids were the same on four apps** (e.g. the AIGC question, the filing type), confirming they belong to the compliance; asc still reads them from Apple's form every time (law 8).
- **REST statuses**: 404 no such requirement on the app; 409 not declarable now, read-only, or a form asc doesn't understand; 422 evidence missing, mismatched or of a type the field refuses; 403 the role can't edit; 401 no team.

## 7 · Open questions

1. ~~**Where does the list of applicable requirements come from?**~~ **ANSWERED: `…/accounts/{accountId}/requirements?entity_id={appId}`.** It lists answered and unanswered requirements, with `formName`, `countries`, `isRequired` and `status` (`PENDING_COLLECT` when unanswered). No hard-coded list is needed.
2. ~~**What does Save target, and what does it send?**~~ **ANSWERED.** A first answer: `POST …/entities/{appId}/forms` with `{ accountId, entityId, requirementId, fields }`, answered with the new declaration. A change: `PUT …/entities/{appId}/forms/{formId}` with the same body plus `formId`, answered with the same declaration and a new `updatedAt`. A `RADIO` or `TEXT` field is `{ id, sValue }`; a `FILE` field is `{ id, fileContent: { fileData: <base64>, fileName, fileType } }`, stored as `{ fileId, fileName, fileType, fileSizeBytes }`.
3. **What are the other wire values?** Seen, on the requirement and the declaration alike: `PENDING_COLLECT` (unanswered), `COLLECTED_VERIFY_PENDING` (a Yes awaiting Apple, with `requiredActions`) and `COLLECTED_VERIFY_NOT_NECESSARY` (a No, with no `requiredActions`). **Working assumption until Apple reviews one:** a verified Yes becomes Active, and a failed one becomes Verification Failed and editable again, so the developer can correct it and resubmit (law 5 offers `declare` on it; law 5a still lets Apple's `editable` decide). Their wire values are unseen and stay `.unrecognized(raw)`, shown raw, until captured.
4. ~~**Are `formName` codes stable?**~~ **DECIDED: match the exact `formName`.** `SECURITYASF395E` and `AIGENERATEFD1DE` map to their kinds; any other code is `.unrecognized(formName)`, listed as-is and never offered `declare` (law 4). If Apple renames a code, the row still lists and only `declare` stops until the mapping is updated.
5. ~~**Who can edit?**~~ **ANSWERED: whoever can sign in to App Store Connect with access to the app.** The tool adds no role check of its own and simply uses the signed-in session. If Apple refuses a save anyway (the help page reserves the China identity verification for Account Holder or Admin), the 403 is reported as "your App Store Connect role can't edit App Compliance for this app", never as a bare HTTP error.
6. ~~**Should check-readiness warn?**~~ **DECIDED: only when the app is available in a requirement's region.** A requirement that isn't Active (Missing Info, Pending Verification, Verification Failed) warns only if one of its `countries` (`CHN`) is among the territories the app is available in (the public API's app availability). An app not sold in China mainland gets no warning. It is a warning, not a blocker, and says the region and the deadline (2027-01-31). The rule joins compliance to availability, so it is the first one that earns an `AppCompliance` collection type; that type and the readiness rule are their own slice after the list ships.
7. ~~**Is there a public API or SDK support?**~~ **ANSWERED: no.** Not in appstoreconnect-swift-sdk 4.6.0/4.6.1 or Apple's OpenAPI 4.6 (checked 2026-11-17). Private `/ppm/` endpoint only.
8. ~~**Where does `accountId` come from?**~~ **ANSWERED: olympus `publicProviderId`.** It matched the `teamId` saved by `asc iris auth login`.
9. ~~**How is the metadata asked for with a draft?**~~ **ANSWERED: `POST …/metadata` with `{ accountId, entityId, requirementId, form: { fields: [ … ] } }`.** Opening the modal sends `fields: []`; each pick on a `valueDeterminesMetadata` field sends it again, and the response adds that branch's fields. Every AIGC branch is captured except third-party No, which presumably asks for nothing more.
10. **What does `requiredActions` mean?** **Working assumption:** `APP_BINARY_SUBMISSION` means Apple verifies the declaration when the app is next submitted for review, and the row stays Pending Verification until then. The CLI shows it as "verified at your next submission for review". Not confirmed; other values are unseen and are shown raw.
11. ~~**How is a file uploaded?**~~ **ANSWERED: it isn't, separately.** The file goes inside the draft as `fileContent: { fileData: <base64>, fileName, fileType }`, and Apple stores it on save as `{ fileId, fileName, fileType, fileSizeBytes }`. Still unknown: the size limit.
12. ~~**Are constraint ids the same for every app?**~~ **ANSWERED for one account: yes.** A second app showed the same constraint ids and even the same requirement id, so requirement and field ids belong to the regulation, not to the app. Law 8 still finds fields by their loc-key slug and never hard-codes an id, because another account is unseen and Apple can change a form; the shared requirement id is why law 2 addresses a row by requirement id and app together.
