#!/bin/bash
# Lanista iOS Release Script
# Runs widget tests → builds IPA → uploads to TestFlight
#
# Usage:
#   bash scripts/release_ios.sh
#   bash scripts/release_ios.sh "Fix: messaging from Matches tab"   # custom changelog

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

CHANGELOG=${1:-"New build — see git log for changes"}

echo ""
echo "========================================"
echo "  Lanista iOS Release"
echo "========================================"
echo ""

# Step 1: Widget tests (fast, no device required)
echo "[1/3] Running widget tests..."
flutter test test/
echo "      ✓ Widget tests passed"
echo ""

# Step 2: Build IPA
echo "[2/3] Building release IPA..."
flutter build ipa \
  --dart-define-from-file=../dart_defines/dev.json \
  --export-options-plist=ios/ExportOptions.plist
echo "      ✓ Build complete"
echo ""

# Step 3: Upload to TestFlight via xcrun altool
echo "[3/3] Uploading to TestFlight..."
IPA_PATH=$(find build/ios/ipa -name "*.ipa" | head -1)
if [ -z "$IPA_PATH" ]; then
  echo "ERROR: No IPA found in build/ios/ipa/"
  exit 1
fi

xcrun altool --upload-app \
  --type ios \
  --file "$IPA_PATH" \
  --apiKey "$APP_STORE_API_KEY_ID" \
  --apiIssuer "$APP_STORE_API_ISSUER_ID"

echo "      ✓ Uploaded to TestFlight"
echo ""

echo "========================================"
echo "  iOS release complete!"
echo "  Build will appear in TestFlight once"
echo "  Apple finishes processing (~10 min)."
echo "========================================"
