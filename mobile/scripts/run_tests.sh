#!/bin/bash
# Lanista Test Runner
# Usage:
#   bash scripts/run_tests.sh                          # emulator (default: emulator-5554)
#   bash scripts/run_tests.sh emulator-5554            # Android emulator
#   bash scripts/run_tests.sh 00008150-00011CDA3644401C  # iPhone via USB
#
# Run from the mobile/ directory or anywhere — the script resolves its own path.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

DEVICE=${1:-"emulator-5554"}

echo ""
echo "========================================"
echo "  Lanista Test Suite"
echo "  Device: $DEVICE"
echo "========================================"
echo ""

echo "--- Widget tests (no device required) ---"
flutter test test/
echo ""

echo "--- Integration tests on device: $DEVICE ---"
flutter test integration_test/ \
  --dart-define-from-file=../dart_defines/dev.json \
  -d "$DEVICE"
echo ""

echo "========================================"
echo "  All tests passed!"
echo "========================================"
