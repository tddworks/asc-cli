# App Compliance — "Does your app offer AIGC services in China mainland?"

**Status: DESIGN. Nothing is built.** Apple has no public API for App Compliance: it is absent from appstoreconnect-swift-sdk 4.6.1 and from Apple's own OpenAPI spec 4.6 (checked 2026-11-17). The web UI reads it from a private endpoint outside `/iris/v1`, which uses the same Apple ID session cookies. One read call has been captured (below). The requirements list, the save call and the document upload have **not** been captured, and slices that depend on them are marked *blocked*.

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
  "Edit" / "Add Info"                       ← the next action depends on status
  "Does your app offer AIGC services in China mainland?"  Yes / No
  Help: "complete the AI-generated/synthetic content and Security Assessment declarations"
  Help: Yes → filing number + filing name (AIGC); proof screenshot + assessment report (Security Assessment)
```

So the domain is a **checklist of requirements**, and each requirement takes a **yes/no declaration**. Answering Yes also requires evidence, and the kind of evidence depends on the requirement. Answering No requires none.

The same page also holds the Digital Services Act trader status, the ICP filing number, the Vietnam game license and the regulated medical device declaration. They are **out of scope** for this lap. They are separate cards with their own shapes and haven't been captured.

## The one sentence

**An app's compliance is the list of regional requirements that apply to it, each answered by a declaration whose status says whether the app may stay on sale in that region.**

```
 App 1234567890
  ├─ Security Assessment       China mainland   declaration: No   → Active
  └─ AI Generated or Synthetic China mainland   (none)            → Missing Info  → declare
```

## The captured wire format

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

- `accountId` is the team's **`publicProviderId`** from `olympus/v1/session`. It already arrives as `IrisAuthSession.teamId`, and the captured URL matched a saved session's `teamId`. It is **not** the numeric `providerID`.
- `entities/{appId}` is the numeric App Store app ID.
- Timestamps are epoch milliseconds, encoded as strings.
- The second captured form was `AIGENERATEFD1DE`, with the same shape.
- **Only answered requirements come back.** A "Missing Info" row has no form, so the list of what applies has to come from another call (Open question 1).

---

## 1 · Ubiquitous language

| Term | Meaning | Not to be confused with |
|---|---|---|
| **App Compliance** | The page: every compliance requirement for one app | Export compliance on a build |
| **Compliance requirement** | One regulation that applies to the app in a region ("Security Assessment, China mainland"). Apple's API calls it a *requirement* | The help-page article about it |
| **Kind** | Which regulation the requirement is. This lap covers Security Assessment and AI Generated or Synthetic Content | Apple's `formName` code, which is only how the wire spells it |
| **Declaration** | The developer's answer to one requirement. Apple's API calls it a *form* | `AgeRatingDeclaration`, `AppEncryptionDeclaration`, `AccessibilityDeclaration`: public-API resources with no relation to this one |
| **Answer** | Yes (the app offers the regulated feature in the region) or No (it doesn't, or the feature is disabled or geoblocked there) | |
| **Evidence** | What a Yes must carry: filing number and filing name (AIGC), or proof screenshot and assessment report (Security Assessment) | |
| **Status** | Missing Info · Pending Verification · Verification Failed · Active | The raw wire value (`COLLECTED_VERIFY_NOT_NECESSARY`) |
| **Account** | The team, identified by `publicProviderId` (a UUID) | `providerID`, the numeric ID |

**"Declaration", not "form".** *Form* is Apple's backstage word. Apple's help page and the people filling it in say *declaration*. The `formName` code stays in the infrastructure mapper.

## 2 · The aggregate — from the root down

```
ComplianceRequirement                  one row on the App Compliance page (aggregate root)
 ├─ id        : String                 Apple's requirementId; stable before and after answering
 ├─ appId     : String                 parent; injected by the adapter (the API omits it)
 ├─ kind      : ComplianceKind         which regulation; decides what a Yes must carry
 ├─ region    : String?                "China mainland"; from the requirements call (blocked)
 ├─ updatedAt : Date?                  nil = never answered ("-")
 ├─ declaration : ComplianceDeclaration?   nil ⇒ MISSING INFO, always
 │   ├─ id     : String                Apple's form id; what an update targets (assumed, Open question 2)
 │   └─ answer : ComplianceAnswer      .notOffered | .offered(Evidence) — EVIDENCE ONLY ON YES
 └─ status    : ComplianceStatus       derived: no declaration → missingInfo; else mapped from wire
```

There is no `AppCompliance` wrapper type. It would just be the plural of `ComplianceRequirement`, with no rule of its own yet. It earns a type if Open question 6 ("may this app ship in region X?") gets answered, because that rule belongs to the collection.

## 3 · The kinds and the rich types

| Kind | Wire `formName` | A Yes must carry | Its own rules |
|---|---|---|---|
| **securityAssessment** | `SECURITYASF395E` | proof-of-pass screenshot + assessment report (sealed) | Required when the app distributes AIGC or offers encrypted instant messaging |
| **aiGeneratedContent** | `AIGENERATEFD1DE` | LLM/algorithm filing number + filing name; optional third-party authorization | |
| **unrecognized(formName)** | anything else | unknown | Listed as-is, never offered `declare` |

### `ComplianceAnswer` — the developer's Yes or No

> **Pointable as:** the radio button the developer ticked in the Yes/No dialog.

| | |
|---|---|
| **Owns — a Yes carries its kind's evidence; a No carries nothing** | `.notOffered` has no payload. `.offered(SecurityAssessmentEvidence)` and `.offered(AIGCFilingEvidence)` are different shapes, so a Yes without a filing number can't be built |
| **It answers** | `wireValue` → `"YES"` / `"NO"` |
| **Never** | A `filingNumber` field that "is ignored when the answer is No" |

### `ComplianceStatus` — what the STATUS column says

> **Pointable as:** the icon and label in the STATUS column.

| | |
|---|---|
| **Owns — an unknown wire status still lists** | `.missingInfo · .pendingVerification · .verificationFailed · .active · .unrecognized(raw)` |
| **It answers** | `isActive` (the app may stay on sale in the region) · `needsAction` (Missing Info or Verification Failed) · `isPendingVerification` |
| **Never** | Guess a mapping. Only `COLLECTED_VERIFY_NOT_NECESSARY → active` is observed; every other wire value is `.unrecognized` until captured (Open question 3) |

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

`IrisClient` hard-codes the base `…/iris/v1`. It gets a second entry point for `…/ppm/compliancerequirements/v1` with the same cookies and headers. There is no new auth path.

## 5 · Invariants (each law, one owner)

| # | Law | Owner |
|---|---|---|
| 1 | A requirement nobody has answered shows Missing Info | `ComplianceRequirement` (derives `status`) |
| 2 | A requirement always belongs to the app it was listed under | adapter mapper (injects `appId`) |
| 3 | A Yes always carries its kind's evidence; a No carries none | `ComplianceAnswer` (shape) |
| 4 | An unknown form or status is still listed, never dropped and never a crash | `ComplianceKind` / `ComplianceStatus` (`.unrecognized`) |
| 5 | You're offered `declare` only for a recognized kind that isn't awaiting verification | `ComplianceRequirement.structuredAffordances` |
| 6 | The account in the URL is the team's `publicProviderId`, never the numeric `providerID` | adapter (account resolution) |

## 6 · Build sequence (test-first, each slice green)

0. **Capture** *(blocking 2–5)*: in the browser network tab, capture the requirements/applicability call (names, regions, IDs for unanswered rows), the Save request for No and for Yes, the status values for Pending/Failed, and the document upload calls.
1. **Domain**: `ComplianceKind`, `ComplianceStatus`, `ComplianceAnswer` (No only), `ComplianceRequirement` + affordances, `@Mockable IrisComplianceRepository`. *Pinned: laws 1, 3 (No), 4, 5.*
2. **Infrastructure read**: `IrisClient` ppm base; account resolution; `listRequirements(session:appId:)` decoding the captured fixture, with placeholder IDs. *Pinned: laws 2, 6; epoch-ms dates; unknown `formName` survives.*
3. **`asc iris app-compliance list` + REST** `GET /api/v1/iris/apps/:appId/compliance-requirements`. *Pinned: full JSON snapshot; `_links.declare` only on eligible rows.*
4. **`declare --answer no` + REST** `POST /api/v1/iris/compliance-requirements/:requirementId/declare` *(blocked on the Save capture)*.
5. **Yes with evidence** *(blocked on the upload capture)*: per-kind evidence types and file flags.
6. **Docs**: `README.md` for users, one CHANGELOG line, `make docs`, and a link from the iris README's "Other iris commands".

## 7 · Open questions

1. **Where does the list of applicable requirements come from?** `/forms` returns only answered ones, so a Missing Info row is invisible to it. A sibling call (likely `…/entities/{appId}/requirements`) is expected to provide names, regions and IDs. *Blocking for slice 2.* Hard-coding the two China requirements is the fallback, but that breaks as soon as Apple adds a region.
2. **What does Save target: the requirement or the form?** A first answer has no form yet, so it probably POSTs against `requirementId` and later edits PATCH the form `id`. Decide from the capture.
3. **What are the wire values for Pending Verification, Verification Failed and a Yes awaiting review?** Until captured, they map to `.unrecognized(raw)` and are shown raw.
4. **Are `formName` codes stable?** `SECURITYASF395E` / `AIGENERATEFD1DE` look like a prefix plus a hash. Recommendation: match the exact code and fall through to `.unrecognized`. If the requirements call gives a stable key, use that instead.
5. **Who can edit?** The help page requires Account Holder or Admin for the China identity verification. If declarations need it too, a 403 should say so rather than surfacing as a bare HTTP error.
6. **Should check-readiness warn?** Apple removes non-compliant apps from the China mainland store (deadline 2027-01-31), and a failed verification removes the app there. A readiness check "China mainland compliance not Active" would be the first rule that needs an `AppCompliance` collection type. Deferred until the list ships.
7. ~~**Is there a public API or SDK support?**~~ **ANSWERED: no.** Not in appstoreconnect-swift-sdk 4.6.0/4.6.1 or Apple's OpenAPI 4.6 (checked 2026-11-17). Private `/ppm/` endpoint only.
8. ~~**Where does `accountId` come from?**~~ **ANSWERED: olympus `publicProviderId`.** It matched the `teamId` saved by `asc iris auth login`.
