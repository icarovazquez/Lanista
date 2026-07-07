#!/bin/bash
# Build and distribute Android APK to Firebase App Distribution
set -e

export PATH="/Users/icaro/.nvm/versions/node/v20.20.0/bin:/usr/local/share/flutter/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
MOBILE_DIR="$ROOT_DIR/mobile"
FIREBASE_APP_ID="1:237263599895:android:0779cd0150b5bad77c5f52"
APK_PATH="$MOBILE_DIR/build/app/outputs/flutter-apk/app-release.apk"

echo "==> Building release APK..."
cd "$MOBILE_DIR"
flutter build apk --release --dart-define-from-file=../dart_defines/dev.json

echo ""
echo "==> APK built: $APK_PATH"
echo ""

echo "==> Uploading to Firebase App Distribution..."
cd "$ROOT_DIR"
firebase appdistribution:distribute "$APK_PATH" \
  --app "$FIREBASE_APP_ID" \
  --groups "lanista-android-testers" \
  --release-notes "${1:-New build}"

echo ""
echo "==> Done! Testers will receive an email with the download link."
