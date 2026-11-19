---
description: File-by-file detail of the documentation layout, written from the reader's side. For each file: who opens it, the question they bring, a mockup, and what stays out.
---

# Layout in Detail

Companion to [the design](README.md). Each file below is described from the **reader's side**: who opens it, what question they have, and what they should see. Anything that doesn't answer that question belongs in a different file.

## Which file answers my question?

| I am… | …and I want to know | I open |
|---|---|---|
| Evaluating the tool | What is this? Can I try it in a minute? | `README.md` |
| Upgrading | What changed? Will my scripts break? | `CHANGELOG.md` |
| Looking for a feature | Does asc do X? Where is it documented? | `docs/README.md` |
| Using a feature | How do I do the job? What will bite me? | `docs/features/<x>/README.md` |
| Writing a script | What is the exact flag name? | `docs/commands.md` or `asc <cmd> --help` |
| Scripting a release | What's the end-to-end order? | `docs/release.md` |
| Embedding in Swift | How do I use it as a package? | `docs/library.md` |
| Contributing | How do I build, test, and where does code go? | `CONTRIBUTING.md` → `docs/design.md` |
| An agent working in this repo | What must I never do? | `CLAUDE.md` |

---

## `CHANGELOG.md`

**Who:** someone upgrading from version N to N+k, a script owner after CI broke, or someone checking whether their bug is fixed.

**Their questions, in order:**
1. **Will this break me?** They need to see anything removed or changed incompatibly first, and what to do about it.
2. **Is my bug fixed?** They skim for the command they use.
3. **What's new that I could use?**
4. **Where do I learn more?** One link.

They don't care which Swift type, repository method or SDK call changed; that's for reviewers and belongs in the PR.

### Rules

| Rule | Why (reader's view) |
|---|---|
| Keep a Changelog headings; **`Removed` and `Changed` come before `Added`** | Question 1 is answered before anything else |
| Anything that breaks existing use starts with **`Breaking:`** and says what to do instead | Script owners can grep for "Breaking" across versions |
| Each bullet starts with **what the user types** (`` `asc builds list` ``, `` `GET /api/v1/…` ``) | They're scanning for *their* command |
| Say the **effect**, not the implementation: "returns every page", not "uses `requestAllPages`" | They can check the effect; they can't check the implementation |
| One bullet per user-visible change, **≤300 chars**; merge related fixes into one bullet | Nine one-line bullets about pagination are the same news |
| Every bullet ends with its PR link; bullets that change how you use asc also get `→ [docs](…#section)` | Two ways down: *how do I use it* (feature doc) and *why did it change* (PR). No changelog-only files. |
| Mention REST only when a route is **new, changed or removed** | Every feature has REST; saying so every time is noise |
| `## [Unreleased]` is always at the top; releasing means renaming that heading | One edit per release |
| Only the current minor lives here; each past minor is in `docs/changelog/<minor>.md`, linked under "Older releases" | The file an upgrader or agent opens stays ~50–150 lines. Anyone upgrading across minors follows one link per minor. |

### Before → after (real entries)

**Before (0.17.8):** a removed REST route is hidden at the end of an 1,100-char `Added` bullet:

> - **`asc iris iap-submissions delete --submission-id <id>`** — iris-side dequeue of an IAP submission (`DELETE /iris/v1/inAppPurchaseSubmissions/{id}`). Iris-queued submissions don't round-trip through the public-SDK delete; they can only be removed via this iris-cookie-authed path. New `IrisClient.delete`, new `IrisInAppPurchaseSubmissionRepository.deleteSubmission(session:submissionId:)`. REST equivalent: … `RESTPathResolver.resourcePath` now converts spaces … Removed the short-lived public-SDK alias `POST /api/v1/iap/:iapId/unsubmit` (incorrect — …).

A script calling `POST /api/v1/iap/:iapId/unsubmit` broke, and the only notice was the last sentence of a bullet about something else.

**After:**

```markdown
## [0.17.8] - 2026-04-29

### Removed
- **Breaking:** `POST /api/v1/iap/:iapId/unsubmit` is gone — it never worked for iris-queued submissions. Use `DELETE /api/v1/iris/iap-submissions/:id`.

### Added
- `asc iris iap-submissions delete --submission-id <id>` removes an IAP from the next version's review queue; the `removeFromNextVersion` affordance now runs it. → [docs](docs/features/iap-subscriptions/submission-iris-parity.md) ([#PR](…))
```

**Before (0.18.4):** six `Fixed` bullets, about 3,900 chars, full of `limit=200`, `SubscriptionPriceInlineCreate` and `APIClient.requestAllPages`.

**After:**

```markdown
## [0.18.4] - 2026-09-23

### Fixed
- List commands no longer stop at Apple's first 20–50 results — e.g. `builds uploads list` (50 → 122 on a real account), `bundle-ids list`, `profiles list`, and every per-territory price list.
- `asc subscriptions prices set-batch` sends one all-or-nothing request instead of one per territory (175 for a full price list), so a failure no longer leaves prices half-applied.
- `asc subscription-price-schedule get` shows the correct custom price for every territory, not just the first 50.
- Offer `prices list` commands now include each price's territory and price point.
- `asc profiles list` shows each profile's bundle ID again.
```

Same news for the reader, about a quarter of the length. The implementation detail isn't lost: each bullet's PR link leads to it.

**Old entries:** wording left as it is and moved unchanged to `docs/changelog/<minor>.md`. The new style applies going forward (see Decisions).

### What the file looks like

```markdown
# Changelog
Format: Keep a Changelog · Versioning: SemVer

## [Unreleased]

## [0.18.4] - 2026-09-23
### Fixed
- List commands no longer stop at Apple's first 20–50 results — … ([#NN](…))

## [0.18.3] - 2026-09-22
…
## [0.18.0] - 2026-05-13
…

## Older releases
[0.17](docs/changelog/0.17.md) · [0.16](docs/changelog/0.16.md) · [0.1](docs/changelog/0.1.md)
```

---

## `README.md` (≤150 lines)

**Who:** someone who found the repo, from a link, Homebrew search or an agent recommendation.
**Their question:** *What is this, is it for me, and can I see it work in a minute?*

```markdown
# asc-cli                                          ← logo + 4 badges
App Store Connect from your terminal, CI, or AI agent. JSON output with
next-step commands built in.                        ← 2-line pitch

## Quick start                                      ← ~12 lines
brew install asccli
asc auth login --key-id … --issuer-id … --private-key-path …
asc apps list
asc init --app-id <id>

## Built for agents                                 ← ~20 lines
One JSON example with `affordances`, 2 sentences on CAEOAS → docs/design.md

## What it covers                                   ← the existing Features table,
| Area | What you can do |                           each row links to its feature doc
| TestFlight | Beta groups, testers, CSV import… → [docs](docs/features/testflight/README.md) |
…

## More                                             ← 5 links, nothing else
Docs index · Release workflow · Use as a Swift package · Contributing · Changelog

## Sponsors · App Wall · License
```

**Not here:** per-command examples, the auth account model, iris sign-in, the SPM API or the development setup. Each has one home, listed in [the design](README.md#readmemd-150-lines).

---

## `docs/README.md` (generated)

**Who:** a user who knows *what job* they have but not which command does it.
**Their question:** *Does asc do X, and where is it documented?*

Built by `make docs` from each feature doc's `description`. It is never edited by hand; CI fails if it's stale.

```markdown
# asc-cli docs
<!-- GENERATED by `make docs` from docs/features/*/README.md frontmatter. Do not edit. -->

Start with the [README](../README.md). For exact flags, see [commands](commands.md).

| Feature | What it's for |
|---|---|
| [age-rating](features/age-rating/README.md) | Set the age-rating questionnaire answers. Use before first submission or when content changes. |
| [app-clips](features/app-clips/README.md) | … |
| [testflight](features/testflight/README.md) | Manage beta groups and testers, import/export CSV. Use when distributing a build to testers. |
…

Guides: [release](release.md) · [library](library.md) · [design](design.md)
```

**Alphabetical, not grouped.** Grouping by task would need a `group:` field in every doc plus a rule for which group each feature belongs to, which is more to maintain. Browser find (Ctrl-F) across 45 one-line descriptions is enough. Add grouping only if people actually get lost.

---

## `docs/features/<x>/README.md` (≤200 lines)

**Who:** a user (or an agent following a skill) about to do a job with one feature.
**Their question:** *How do I get this done, and what will surprise me?*

They **don't** need flag tables, which `--help` already has, or architecture, which lives in the source. Mockup of today's `testflight.md` (465 lines) after it moves to `testflight/README.md` and is trimmed:

````markdown
---
description: Manage beta groups and testers, import/export CSV. Use when distributing a build to testers.
---

# TestFlight

Beta groups and testers: create groups, invite people, move testers between groups with CSV.
Every flag: [commands.md#testflight](../../commands.md#asc-testflight).

## Quick start
```bash
asc testflight groups list --app-id 1234567890
asc testflight testers add --beta-group-id g-abc123 --email jane@example.com
```

## Workflows

### Copy testers from one group to another
```bash
asc testflight testers export --beta-group-id g-old > testers.csv
asc testflight testers import --beta-group-id g-new --file testers.csv
```

### Open a public beta
```bash
asc testflight groups create --app-id 1234567890 --name "Public Beta" --public-link-enabled
```

## REST
| Method | Path | CLI |
|---|---|---|
| GET | `/api/v1/apps/:appId/testflight` | `asc testflight groups list --app-id` |

## Gotchas
- CSV must have the header `email,firstName,lastName`; `export` writes exactly that, so export → import round-trips.
- `--public-link-enabled` and `--feedback-enabled` only apply to external groups (no `--internal`).
- Only group listing is exposed over REST today; tester changes are CLI-only.

## See also
[beta-review](../beta-review/README.md) · [builds-upload](../builds-upload/README.md) · [asc-testflight skill](../../../skills/asc-testflight/SKILL.md)
````

About 45 lines instead of 465. Everything removed is either in `--help` (flags, defaults), in the source (domain models, file map, tests), or was a copy of an affordance the JSON already shows.

**When it outgrows 200 lines:** move one topic into `docs/features/<x>/<topic>.md` next to the README and link to it from "See also", as `iap-subscriptions/pricing.md` already does. The README's own path doesn't change.

---

## `docs/commands.md` (generated)

**Who:** a script author who needs the exact flag, or an agent checking a flag without a shell.
**Their question:** *What's the exact spelling, and is it required?*

Generated by `make docs` from `asc --experimental-dump-help`, so it is exactly what the binary accepts. One section per command, with stable anchors for feature docs to link to:

````markdown
<!-- GENERATED by `make docs` from `asc --experimental-dump-help`. Do not edit. -->
# Command reference — asc 0.18.4

## asc testflight testers import
Import beta testers from a CSV file (columns: email,firstName,lastName)

```
asc testflight testers import --beta-group-id <id> --file <file> [--output <output>] [--pretty] [--timeout <timeout>]
```

| Flag | Required | Description |
|---|---|---|
| `--beta-group-id` | yes | Beta group ID |
| `--file` | yes | Path to CSV file with columns: email,firstName,lastName |
````

Global flags (`--output`, `--pretty`, `--timeout`) are listed once at the top, not repeated on every command. To improve a description, edit the `help:` string in Swift. That one edit fixes `--help`, this file and every link to it.

---

## `docs/release.md`

**Who:** someone shipping a version, by hand or in CI.
**Their question:** *What's the order, and what do I check before submitting?*

The numbered README "Release Workflow" moved here (upload → TestFlight → version → What's New → check-readiness → submit). Each step is one command plus a link to its feature doc. The per-feature detail stays in the feature docs.

## `docs/library.md`

**Who:** a Swift developer embedding asc in their own tool.
**Their question:** *How do I add the package and get a repository?*

The README's "Use as a Swift Package" section moved here: the dependency snippet, a 20-line example and the `ClientFactory` list.

## `docs/design.md`

**Who:** a contributor or curious user asking *why* it's built this way.
**Their question:** *What is CAEOAS, and why three layers?*

Today's `desgin.md`, renamed. It's the **one** home for the architecture diagram, which is why feature docs no longer draw their own.

## `CONTRIBUTING.md`

**Who:** a first-time contributor.
**Their question:** *How do I build, run the tests, and open a PR that gets merged?*

```markdown
# Contributing
## Build & test          swift build · swift test · make run ARGS="apps list"
## How code is organised 3 lines + link to docs/design.md
## Rules                 TDD first (link), every command ships CLI + REST (link)
## Docs                  the update-rules table from docs/documentation-design/, by link
```

## `CLAUDE.md` (≤100 lines)

**Who:** an AI agent at the start of *every* session in this repo.
**Its question:** *What must I always or never do here?*

```markdown
# CLAUDE.md
## TDD is non-negotiable      ← unchanged gate (~20 lines)
## Commands                   ← build / test / run (~10 lines)
## Architecture               ← 3 layers + dependency rule + CAEOAS in 1 paragraph (~15 lines)
## When you are…              ← pointers, loaded only when relevant
- adding a feature  → implement-feature skill (REST checklist, domain rules, docs)
- improving one     → improvement skill
- touching docs     → docs/documentation-design/
## Authentication             ← 5 lines + link to docs/features/asc-auth/README.md
```

**Moved out:** the REST exposure checklist, the domain folder tree, the doc-update table and the localization-types table. The first goes to the `implement-feature` skill, the tree is deleted (`ls Sources/Domain`), and the rest go to the skill or the feature doc.
