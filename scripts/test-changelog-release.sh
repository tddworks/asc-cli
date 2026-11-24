#!/bin/bash
# Regression test for the release-time changelog scripts:
# extract-changelog.sh → promote-changelog.sh (which runs changelog-rollover.py).
# Runs the same sequence as .github/workflows/release.yml on copies of the real
# CHANGELOG.md and docs/changelog/, for patch and minor releases, with and without
# [Unreleased] entries. Usage: scripts/test-changelog-release.sh

set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
FAILURES=0

fail() { echo "  FAIL: $*"; FAILURES=$((FAILURES + 1)); }

# Version numbers derived from the newest release, so the test keeps working after releases.
LATEST=$(grep -m1 -oE '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' "$ROOT/CHANGELOG.md" | tr -d '#[] ')
IFS=. read -r MAJOR MINOR PATCH <<< "$LATEST"
NEXT_PATCH="$MAJOR.$MINOR.$((PATCH + 1))"
NEXT_MINOR="$MAJOR.$((MINOR + 1)).0"

run_case() {
    local version=$1 empty_unreleased=$2 expect_rollover=$3
    echo "case: release $version (latest $LATEST), empty [Unreleased]: $empty_unreleased"

    local dir; dir=$(mktemp -d)
    mkdir -p "$dir/scripts" "$dir/docs"
    cp "$ROOT/CHANGELOG.md" "$dir/"
    cp -r "$ROOT/docs/changelog" "$dir/docs/"
    cp "$ROOT"/scripts/{extract-changelog.sh,promote-changelog.sh,changelog-rollover.py} "$dir/scripts/"
    cd "$dir"

    if [ "$empty_unreleased" = yes ]; then
        python3 - <<'PY'
s = open("CHANGELOG.md").read()
a = s.index("## [Unreleased]") + len("## [Unreleased]")
b = s.index("\n---", a)
open("CHANGELOG.md", "w").write(s[:a] + "\n" + s[b:])
PY
    fi
    local headings_before; headings_before=$(cat CHANGELOG.md docs/changelog/*.md | grep -c '^## \[')

    ./scripts/promote-changelog.sh "$version" 2026-01-01 > /dev/null
    local notes; notes=$(./scripts/extract-changelog.sh "$version")

    # Release notes contain only this version's entries
    grep -q 'Older releases' <<< "$notes" && fail "release notes include the 'Older releases' line"
    grep -qE '^\[[^]]+\]: ' <<< "$notes" && fail "release notes include reference links"
    grep -q '^## ' <<< "$notes" && fail "release notes include another section heading"
    [ -n "$notes" ] || fail "release notes are empty"
    if [ "$empty_unreleased" = yes ]; then
        grep -q 'Bug fixes and improvements.' <<< "$notes" || fail "empty release did not get the default entry"
    fi

    # [Unreleased] is reset and the new version sits right below it
    [ "$(grep -m2 '^## \[' CHANGELOG.md | tail -1)" = "## [$version] - 2026-01-01" ] || fail "new version is not the first release"
    [ -z "$(./scripts/extract-changelog.sh "0.0.0-none" 2>/dev/null)" ] || fail "[Unreleased] is not empty after promotion"

    # Only the current minor stays in CHANGELOG.md
    local minors; minors=$(grep -oE '^## \[[0-9]+\.[0-9]+' CHANGELOG.md | sort -u | wc -l | tr -d ' ')
    [ "$minors" = 1 ] || fail "CHANGELOG.md holds $minors minors"
    if [ "$expect_rollover" = yes ]; then
        [ -f "docs/changelog/$MAJOR.$MINOR.md" ] || fail "previous minor not archived to docs/changelog/$MAJOR.$MINOR.md"
        grep -q "(docs/changelog/$MAJOR.$MINOR.md)" CHANGELOG.md || fail "no 'Older releases' link to the new archive"
    else
        [ -f "docs/changelog/$MAJOR.$MINOR.md" ] && fail "patch release archived the current minor"
    fi

    # Archived links still resolve from docs/changelog/ (checked against the real repo)
    local broken; broken=$(python3 - "$ROOT" <<'PY'
import re, sys
from pathlib import Path
root = Path(sys.argv[1])
for path in sorted(Path("docs/changelog").glob("*.md")):
    for target in re.findall(r"\]\(([^)\s]+)\)", path.read_text()):
        if re.match(r"^(https?:|mailto:|#)", target):
            continue
        if not (root / "docs" / "changelog" / target.split("#")[0]).exists():
            print(f"{path}: {target}")
PY
)
    [ -z "$broken" ] || fail "archived links don't resolve from docs/changelog/: $(head -3 <<< "$broken" | tr '\n' ' ')"

    # Nothing lost: every release heading still exists, plus the new one
    local headings_after; headings_after=$(cat CHANGELOG.md docs/changelog/*.md | grep -c '^## \[')
    [ "$headings_after" = $((headings_before + 1)) ] || fail "release headings $headings_before → $headings_after (expected +1)"

    # Rollover is idempotent
    local before; before=$(cat CHANGELOG.md docs/changelog/*.md | shasum)
    python3 scripts/changelog-rollover.py CHANGELOG.md
    [ "$before" = "$(cat CHANGELOG.md docs/changelog/*.md | shasum)" ] || fail "rollover changed files on a second run"

    cd "$ROOT"; rm -rf "$dir"
}

run_case "$NEXT_PATCH" no no
run_case "$NEXT_PATCH" yes no
run_case "$NEXT_MINOR" no yes
run_case "$NEXT_MINOR" yes yes

if [ "$FAILURES" -gt 0 ]; then
    echo "$FAILURES failure(s)"
    exit 1
fi
echo "all changelog release cases pass"
