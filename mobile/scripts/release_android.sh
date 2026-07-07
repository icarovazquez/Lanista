#!/bin/bash
# Lanista Android Release Script
# Runs widget tests → builds release APK → distributes to Firebase App Distribution
#
# Usage:
#   bash scripts/release_android.sh
#   bash scripts/release_android.sh "Fix: messaging from Matches tab"   # custom release notes

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

RELEASE_NOTES=${1:-"New build — see git log for changes"}
FIREBASE_APP_ID="1:237263599895:android:6fd42c1ea33b08607c5f52"
FIREBASE_GROUP="lanista-android-testers"

echo ""
echo "========================================"
echo "  Lanista Android Release"
echo "========================================"
echo ""

# Step 1: Widget tests (fast, no device required)
echo "[1/4] Running widget tests..."
flutter test test/
echo "      ✓ Widget tests passed"
echo ""

# Step 2: Build release APK
echo "[2/4] Building release APK..."
flutter build apk --release \
  --dart-define-from-file=../dart_defines/dev.json
echo "      ✓ Build complete"
echo ""

# Step 3: Distribute via Firebase
echo "[3/4] Distributing to Firebase App Distribution..."
~/.nvm/versions/node/v20.20.0/bin/node /usr/local/bin/firebase \
  appdistribution:distribute \
  build/app/outputs/flutter-apk/app-release.apk \
  --app "$FIREBASE_APP_ID" \
  --project lanista-9caa4 \
  --release-notes "$RELEASE_NOTES" \
  --groups "$FIREBASE_GROUP"
echo "      ✓ Distributed to testers"
echo ""

echo "========================================"
echo "  Android release complete!"
echo "  Testers will receive an email shortly."
echo "========================================"
