#!/bin/bash
# Extract release notes for a specific version from CHANGELOG.md
# Usage: ./scripts/extract-changelog.sh <version> [changelog_file]
# Example: ./scripts/extract-changelog.sh 0.1.3

set -e

VERSION="$1"
CHANGELOG_FILE="${2:-CHANGELOG.md}"

if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version> [changelog_file]" >&2
    exit 1
fi

if [ ! -f "$CHANGELOG_FILE" ]; then
    echo "Error: $CHANGELOG_FILE not found" >&2
    exit 1
fi

# Strip leading 'v' if present
VERSION="${VERSION#v}"

# Extract the section between ## [VERSION] and the next ## [ header (or EOF)
awk -v version="$VERSION" '
    BEGIN { found=0; printing=0 }

    /^## \[/ {
        if (printing) { exit }
        if (index($0, "[" version "]") > 0) {
            found=1; printing=1; next
        }
    }

    printing { print }

    END {
        if (!found) {
            print "Error: Version " version " not found in CHANGELOG.md" > "/dev/stderr"
            exit 1
        }
    }
' "$CHANGELOG_FILE" \
  | sed '/^$/N;/^\n$/d' \
  | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}'