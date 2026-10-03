#!/bin/bash
# Fail unless <version> is higher than every other v* tag, so a typo like
# 0.1.86 (for 0.18.6) can't ship as a downgrade Homebrew never picks up.
# Usage: scripts/check-version-bump.sh <version> [tag...]   (tags default to the origin's v* tags)

set -euo pipefail
VERSION="${1#v}"
shift
if (( $# )); then
    TAGS=$(printf '%s\n' "$@")
else
    TAGS=$(git ls-remote --tags --refs origin 'v*' | sed 's|.*refs/tags/||')
fi
# The tag being released already exists on a tag push; compare against the others.
LATEST=$(sed 's/^v//' <<< "$TAGS" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | grep -vxF "$VERSION" | sort -V | tail -1 || true)

if [ -n "$LATEST" ] && [ "$(printf '%s\n%s\n' "$LATEST" "$VERSION" | sort -V | tail -1)" != "$VERSION" ]; then
    echo "::error::Version $VERSION is not higher than the latest tag v$LATEST" >&2
    exit 1
fi
echo "$VERSION > v${LATEST:-none}"
