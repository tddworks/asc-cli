# Security Policy

asc holds the keys to your App Store Connect account: API keys in `~/.asc/credentials.json`, and for `asc iris` an Apple ID session. A way for those to leak, or for someone else to act on your apps through `asc web-server`, is a security bug. Thank you for reporting one privately.

## Supported versions

Only the latest release gets security fixes. Update with `brew upgrade asccli`.

## Reporting a vulnerability

**Don't open a public issue.** Report it privately on GitHub: [**Report a vulnerability**](https://github.com/tddworks/asc-cli/security/advisories/new) (the Security tab → *Advisories*).

Please include:

- what an attacker can do, and what they need first (a page open in your browser, a local account, a plugin, network access to the `web-server` port, …)
- the asc and macOS versions
- steps or a proof of concept that reproduce it

Leave out real key IDs, issuer IDs, `.p8` keys, Apple ID passwords and session cookies. Redact them in logs and screenshots.

## What to expect

- A first reply within 7 days.
- A fix in a release, credited to you in the advisory and the [CHANGELOG](CHANGELOG.md) unless you'd rather stay anonymous.
- The advisory is published once a fixed version is out.

## Scope

In scope: the `asc` CLI, how it stores and sends credentials, `asc web-server` and the browser UI at asccli.app that talks to it, `asc iris` sessions, plugins and skills it installs, and the Homebrew formula.

Out of scope: flaws in App Store Connect or Apple's APIs (report those to Apple), and third-party plugins you install yourself.
