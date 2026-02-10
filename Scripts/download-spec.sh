#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
INFRA_DIR="$PROJECT_DIR/Sources/Infrastructure"
DEST="$INFRA_DIR/openapi.json"

echo "Downloading App Store Connect OpenAPI spec..."

curl -L -o /tmp/asc-openapi.zip \
  "https://developer.apple.com/sample-code/app-store-connect/app-store-connect-openapi-specification.zip"

echo "Extracting spec..."
unzip -o /tmp/asc-openapi.zip -d /tmp/asc-openapi

# Find the JSON file in the extracted directory
JSON_FILE=$(find /tmp/asc-openapi -name "*.json" -type f | head -1)

if [ -z "$JSON_FILE" ]; then
    echo "Error: No JSON file found in downloaded archive"
    exit 1
fi

cp "$JSON_FILE" "$DEST"
rm -rf /tmp/asc-openapi /tmp/asc-openapi.zip

echo "OpenAPI spec saved to $DEST"
echo "Size: $(wc -c < "$DEST") bytes"
