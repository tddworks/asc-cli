---
description: List and answer an app's App Compliance requirements (China mainland Security Assessment, AI generated content) via the iris web session. Use when App Store Connect asks for compliance info to keep an app on sale in a region.
---

# App Compliance

Read and answer the requirements on an app's **App Compliance** page: the declarations an app keeps current so it can stay on the App Store in a regulated region. Today that is China mainland's **Security Assessment** and **AI Generated or Synthetic Content** (AIGC). Apple has no public API for this page, so it goes through the [iris](../iris/README.md) session. Every flag: [command reference](../../commands.md#asc-iris).

## Quick start

```bash
asc iris app-compliance list --app-id 1234567890 --pretty
asc iris app-compliance declare --app-id 1234567890 --requirement-id <id> --answer no
```

## Workflows

### See what the app still owes

```bash
asc iris app-compliance list --app-id 1234567890 --output table
```

Each requirement is a row, answered or not, with the page's STATUS:

| Status | Meaning | `declare` |
|---|---|---|
| `MISSING_INFO` | Nobody has answered it | offered: a first answer |
| `PENDING_VERIFICATION` | Apple is checking a Yes; `requiredActions: APP_BINARY_SUBMISSION` means it's checked with your next submission for review | not offered: Apple serves it read-only |
| `ACTIVE` | Answered, nothing pending: the app may stay on sale in the region | offered: a change |
| `VERIFICATION_FAILED` | Apple rejected the evidence | offered: a resubmission |

A compliance or status asc doesn't know yet is still listed, as Apple names it, and is never offered `declare`. A row also says which next commands apply (`affordances`, or `_links` over REST). Like the page's table, the list shows each row's status and `declarationId`, not the stored answer or its files.

### Answer No

The app doesn't offer the regulated feature in China mainland, or it's disabled or geoblocked there:

```bash
asc iris app-compliance declare --app-id 1234567890 --requirement-id <id> --answer no
```

A No needs nothing from Apple: the row turns `ACTIVE`.

### Answer Yes with evidence

A Yes must carry its compliance's evidence. Files are `.doc`, `.docx`, `.jpeg`, `.jpg`, `.pdf` or `.png`, and travel inside the declaration.

```bash
# Security Assessment: the proof of a completed assessment, and the assessment report
asc iris app-compliance declare --app-id 1234567890 --requirement-id <id> --answer yes \
  --proof ./proof.pdf --report ./report.pdf

# AI Generated or Synthetic Content: the filing, and the third-party agreement if one applies
asc iris app-compliance declare --app-id 1234567890 --requirement-id <id> --answer yes \
  --filing-type llm --filing-name "Example Model" --filing-number "Example-0000" \
  --third-party-authorization ./agreement.pdf
```

`--filing-type` is `llm` or `algorithm`. Leave out `--third-party-authorization` when the AI features aren't powered by third-party technology. A Yes goes to `PENDING_VERIFICATION`: Apple checks the files and the filing details.

## What asc checks before it saves

- **It asks Apple for the form first**, the way the page does, one answer at a time, and saves exactly the fields Apple asks for. A field it can't fill, or a form Apple serves read-only, stops it before anything is written.
- **Missing evidence is named** ("A Yes to Security Assessment needs the Security Assessment Report.") and nothing is sent.
- **A file type the field doesn't take** is refused before saving.
- **A requirement is found by its id and the app together**: Apple uses the same requirement id on every app.
- **If Apple forbids the save**, you're told your App Store Connect role can't edit App Compliance for that app.

## REST

| Method | Path | CLI equivalent |
|---|---|---|
| GET | `/api/v1/iris/apps/:appId/compliance-requirements` | `asc iris app-compliance list` |
| POST | `/api/v1/iris/apps/:appId/compliance-requirements/:requirementId/declare` | `asc iris app-compliance declare` |

The declare body is `{"answer": "no"}`, or for a Yes, `{"answer": "yes", "evidence": {…}}` with `proof`, `report` and `thirdPartyAuthorization` as `{"name": "proof.pdf", "data": "<base64>"}`, and `filingType` (`llm` / `algorithm`), `filingName`, `filingNumber` as strings. A refusal answers with its reason: 404 (no such requirement on the app), 409 (Apple is verifying it, or serves it read-only), 422 (evidence missing or of the wrong type), 403 (your role can't edit).

## Not the same as

- **Export compliance** (`usesNonExemptEncryption` on a build): see `asc builds`, a public-API resource.
- **Age rating**: see [Age rating](../age-rating/README.md).

Design, wire format and open questions: [design.md](design.md).
